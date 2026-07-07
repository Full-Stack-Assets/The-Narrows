#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "MHWantedSubsystem.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMHOnWantedLevelChanged, int32, NewWantedLevel);

UENUM(BlueprintType)
enum class EMHCrimeType : uint8
{
    TrafficViolation,
    Theft,
    Assault,
    PropertyDamage,
    MissionHeat
};

UCLASS()
class MOUNTHOPE_API UMHWantedSubsystem : public UWorldSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Police")
    FMHOnWantedLevelChanged OnWantedLevelChanged;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ReportCrime(EMHCrimeType CrimeType, int32 Severity);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ReduceHeat(int32 Amount);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ClearWantedState();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void TickWantedDecay(float DeltaSeconds);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    int32 GetWantedLevel() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    int32 GetHeat() const { return Heat; }

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    bool IsPoliceSearching() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    int32 GetSuggestedFine() const;

private:
    UPROPERTY()
    int32 Heat = 0;

    UPROPERTY()
    int32 WantedLevel = 0;

    UPROPERTY(EditDefaultsOnly, Category = "Mount Hope|Police")
    float DecayPerSecond = 3.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Mount Hope|Police")
    float DecayDelaySeconds = 4.0f;

    UPROPERTY(EditDefaultsOnly, Category = "Mount Hope|Audio")
    TObjectPtr<class USoundBase> WantedIncreaseSound;

    float SecondsSinceLastCrime = 0.0f;

    float PendingDecay = 0.0f;

    void RecalculateWantedLevel();
};
