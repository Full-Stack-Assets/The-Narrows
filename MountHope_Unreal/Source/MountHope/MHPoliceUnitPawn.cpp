#include "MHPoliceUnitPawn.h"

#include "Components/StaticMeshComponent.h"
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
}

void AMHPoliceUnitPawn::BeginPlay()
{
    Super::BeginPlay();

    if (SirenSound)
    {
        SirenAudioComponent = UGameplayStatics::SpawnSoundAttached(SirenSound, RootComponent);
    }
}

void AMHPoliceUnitPawn::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    TimeSinceLastCatch += DeltaSeconds;

    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn)
    {
        return;
    }

    // Ground-bound pursuit: chase along XY only (don't fly up to match a player on a rooftop),
    // and sweep the move so the pawn stops at solid geometry instead of tunneling through walls.
    FVector ToPlayer = PlayerPawn->GetActorLocation() - GetActorLocation();
    ToPlayer.Z = 0.0f;
    const FVector Direction = ToPlayer.GetSafeNormal();

    FHitResult MoveHit;
    SetActorLocation(GetActorLocation() + Direction * ChaseSpeed * DeltaSeconds, /*bSweep=*/true, &MoveHit);
    if (!Direction.IsNearlyZero())
    {
        SetActorRotation(Direction.Rotation());
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
