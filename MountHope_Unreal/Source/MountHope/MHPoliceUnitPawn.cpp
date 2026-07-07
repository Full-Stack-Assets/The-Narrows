#include "MHPoliceUnitPawn.h"

#include "Components/StaticMeshComponent.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "MHGameStateSubsystem.h"

AMHPoliceUnitPawn::AMHPoliceUnitPawn()
{
    PrimaryActorTick.bCanEverTick = true;

    BodyMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("BodyMesh"));
    RootComponent = BodyMesh;
    BodyMesh->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    BodyMesh->SetCollisionResponseToAllChannels(ECR_Ignore);
    BodyMesh->SetCollisionResponseToChannel(ECC_Pawn, ECR_Overlap);

    Health = MaxHealth;
}

void AMHPoliceUnitPawn::BeginPlay()
{
    Super::BeginPlay();

    Health = MaxHealth;

    if (SirenSound)
    {
        SirenAudioComponent = UGameplayStatics::SpawnSoundAttached(SirenSound, RootComponent);
    }
}

void AMHPoliceUnitPawn::ConfigureForTier(float InMaxHealth, bool bInArmed)
{
    MaxHealth = FMath::Max(1.0f, InMaxHealth);
    Health = MaxHealth;
    bArmed = bInArmed;
}

void AMHPoliceUnitPawn::ApplyDamage(float DamageAmount)
{
    Health = FMath::Max(0.0f, Health - FMath::Max(0.0f, DamageAmount));
}

void AMHPoliceUnitPawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    if (IsDead())
    {
        // Killing a pursuer removes it; the spawner prunes invalid entries.
        if (GetWorld())
        {
            Destroy();
        }
        return;
    }

    TimeSinceLastCatch += DeltaSeconds;
    TimeSinceLastShot += DeltaSeconds;

    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn)
    {
        return;
    }

    const float DistanceSquared = FVector::DistSquared(GetActorLocation(), PlayerPawn->GetActorLocation());
    State = (bArmed && DistanceSquared <= FMath::Square(AttackRange))
        ? EMHPoliceState::Attack
        : EMHPoliceState::Pursue;

    // Face the player in both states.
    FVector ToPlayer = PlayerPawn->GetActorLocation() - GetActorLocation();
    ToPlayer.Z = 0.0f;
    const FVector Direction = ToPlayer.GetSafeNormal();
    if (!Direction.IsNearlyZero())
    {
        SetActorRotation(Direction.Rotation());
    }

    if (State == EMHPoliceState::Pursue)
    {
        // Ground-bound pursuit: chase along XY only and sweep the move so the pawn
        // stops at solid geometry instead of tunneling through walls.
        FHitResult MoveHit;
        SetActorLocation(GetActorLocation() + Direction * ChaseSpeed * DeltaSeconds, /*bSweep=*/true, &MoveHit);
    }
    else
    {
        TryShootPlayer(PlayerPawn, DistanceSquared);
    }

    TryCatchPlayer(PlayerPawn);
}

void AMHPoliceUnitPawn::TryCatchPlayer(APawn* PlayerPawn)
{
    if (TimeSinceLastCatch < RepeatCatchCooldownSeconds)
    {
        return;
    }

    if (FVector::DistSquared(GetActorLocation(), PlayerPawn->GetActorLocation()) > FMath::Square(CatchRadius))
    {
        return;
    }

    TimeSinceLastCatch = 0.0f;

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
        {
            GameState->ApplyDamage(CatchDamage);
        }
    }
}

void AMHPoliceUnitPawn::TryShootPlayer(APawn* PlayerPawn, float DistanceSquared)
{
    if (TimeSinceLastShot < FireIntervalSeconds)
    {
        return;
    }

    if (DistanceSquared > FMath::Square(AttackRange) || !HasLineOfSightTo(PlayerPawn))
    {
        return;
    }

    TimeSinceLastShot = 0.0f;
    UGameplayStatics::PlaySound2D(this, GunshotSound);

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
        {
            GameState->ApplyDamage(ShotDamage);
        }
    }
}

bool AMHPoliceUnitPawn::HasLineOfSightTo(const APawn* PlayerPawn) const
{
    UWorld* World = GetWorld();
    if (!World || !PlayerPawn)
    {
        return false;
    }

    // NOTE: uses ECC_Visibility; verify the trace channel against the project's
    // collision presets in PIE (the pistol trace uses the same channel).
    FHitResult Hit;
    FCollisionQueryParams QueryParams;
    QueryParams.AddIgnoredActor(this);
    const bool bBlocked = World->LineTraceSingleByChannel(
        Hit, GetActorLocation(), PlayerPawn->GetActorLocation(), ECC_Visibility, QueryParams);

    return !bBlocked || Hit.GetActor() == PlayerPawn;
}
