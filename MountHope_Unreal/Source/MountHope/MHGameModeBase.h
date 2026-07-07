#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "MHGameModeBase.generated.h"

class AMHMissionTriggerActor;
class USoundBase;
struct FMHMissionStep;

UCLASS()
class MOUNTHOPE_API AMHGameModeBase : public AGameModeBase
{
    GENERATED_BODY()

public:
    AMHGameModeBase();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool CompleteCurrentObjective(bool bPlayerInVehicle);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool TryCompleteVehicleObjective(bool bPlayerInVehicle);

protected:
    UPROPERTY(Transient)
    TObjectPtr<AMHMissionTriggerActor> ObjectiveTrigger = nullptr;

    UPROPERTY(EditDefaultsOnly, Category = "Mount Hope|Police")
    float MaxWantedBustedSeconds = 25.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> MissionCompleteSound;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> ObjectiveUpdateSound;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> BustedOrWastedSound;

private:
    bool IsWorldTargetObjective(const FMHMissionStep& Step) const;
    void RefreshObjectiveTrigger();
    void RespawnAtSafehouseIfAvailable();
    void ApplyWeatherFromString(const FString& WeatherName) const;
    void TickBustedTimer(float DeltaSeconds);

    UFUNCTION()
    void HandlePlayerWasted();

    UFUNCTION()
    void HandlePlayerBusted();

    UFUNCTION()
    void HandleHourChanged(int32 Hour);

    float TimeAtMaxWanted = 0.0f;
};
