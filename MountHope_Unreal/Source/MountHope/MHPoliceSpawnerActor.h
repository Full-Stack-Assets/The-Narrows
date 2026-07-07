#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHPoliceSpawnerActor.generated.h"

class AMHPoliceUnitPawn;

// Per-wanted-level pursuit profile: how many units, how tough, and whether they
// carry firearms. Higher stars bring more, tougher, armed cops.
USTRUCT(BlueprintType)
struct FMHPoliceTier
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    int32 UnitCount = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float UnitHealth = 40.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    bool bArmed = false;
};

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHPoliceSpawnerActor : public AActor
{
    GENERATED_BODY()

public:
    AMHPoliceSpawnerActor();

    // Pure map from a wanted level (0-5) to a pursuit profile. Public + world-free
    // so it can be unit-tested directly.
    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    FMHPoliceTier GetTierForWantedLevel(int32 WantedLevel) const;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    TSubclassOf<AMHPoliceUnitPawn> PoliceUnitClass;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float SpawnDistanceMeters = 45.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float DespawnDistanceMeters = 80.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float TickIntervalSeconds = 2.0f;

private:
    void ManagePoliceUnits();
    int32 GetDesiredUnitCount() const;

    UPROPERTY(Transient)
    TArray<TObjectPtr<AMHPoliceUnitPawn>> ActiveUnits;

    FTimerHandle ManageTimerHandle;
};
