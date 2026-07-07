#include "MHPoliceSpawnerActor.h"

#include "Kismet/GameplayStatics.h"
#include "MHPoliceUnitPawn.h"
#include "MHWantedSubsystem.h"
#include "NavigationSystem.h"
#include "TimerManager.h"

AMHPoliceSpawnerActor::AMHPoliceSpawnerActor()
{
    PrimaryActorTick.bCanEverTick = false;
    PoliceUnitClass = AMHPoliceUnitPawn::StaticClass();
}

void AMHPoliceSpawnerActor::BeginPlay()
{
    Super::BeginPlay();
    GetWorldTimerManager().SetTimer(
        ManageTimerHandle,
        this,
        &AMHPoliceSpawnerActor::ManagePoliceUnits,
        TickIntervalSeconds,
        true);
}

int32 AMHPoliceSpawnerActor::GetDesiredUnitCount() const
{
    const UWorld* World = GetWorld();
    const UMHWantedSubsystem* WantedSubsystem = World ? World->GetSubsystem<UMHWantedSubsystem>() : nullptr;
    return WantedSubsystem ? FMath::Min(WantedSubsystem->GetWantedLevel(), 5) : 0;
}

void AMHPoliceSpawnerActor::ManagePoliceUnits()
{
    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn || !PoliceUnitClass)
    {
        return;
    }

    const FVector PlayerLocation = PlayerPawn->GetActorLocation();
    const float DespawnDistanceUnrealUnits = DespawnDistanceMeters * 100.0f;

    for (int32 Index = ActiveUnits.Num() - 1; Index >= 0; --Index)
    {
        AMHPoliceUnitPawn* Unit = ActiveUnits[Index];
        if (!IsValid(Unit))
        {
            ActiveUnits.RemoveAt(Index);
            continue;
        }

        if (FVector::DistSquared(PlayerLocation, Unit->GetActorLocation()) > FMath::Square(DespawnDistanceUnrealUnits))
        {
            Unit->Destroy();
            ActiveUnits.RemoveAt(Index);
        }
    }

    const int32 DesiredCount = GetDesiredUnitCount();

    while (ActiveUnits.Num() > DesiredCount)
    {
        const int32 LastIndex = ActiveUnits.Num() - 1;
        if (AMHPoliceUnitPawn* Unit = ActiveUnits[LastIndex])
        {
            Unit->Destroy();
        }
        ActiveUnits.RemoveAt(LastIndex);
    }

    const float SpawnDistanceUnrealUnits = SpawnDistanceMeters * 100.0f;
    const UNavigationSystemV1* NavSystem = UNavigationSystemV1::GetCurrent(GetWorld());
    while (ActiveUnits.Num() < DesiredCount)
    {
        const float Angle = FMath::FRandRange(0.0f, 2.0f * PI);
        const FVector Offset = FVector(FMath::Cos(Angle), FMath::Sin(Angle), 0.0f) * SpawnDistanceUnrealUnits;
        FVector SpawnLocation = PlayerLocation + Offset;

        // Snap the ring point onto the navmesh so units don't spawn underground, inside
        // buildings, or floating over uneven waterfront terrain; falls back to the flat-Z ring
        // point if no navmesh is present nearby (e.g. before it's baked in the editor).
        if (NavSystem)
        {
            FNavLocation ProjectedLocation;
            if (NavSystem->ProjectPointToNavigation(SpawnLocation, ProjectedLocation, FVector(500.0f, 500.0f, 1000.0f)))
            {
                SpawnLocation = ProjectedLocation.Location;
            }
        }

        AMHPoliceUnitPawn* NewUnit = GetWorld()->SpawnActor<AMHPoliceUnitPawn>(
            PoliceUnitClass,
            SpawnLocation,
            FRotator::ZeroRotator);

        if (!NewUnit)
        {
            break;
        }
        ActiveUnits.Add(NewUnit);
    }
}
