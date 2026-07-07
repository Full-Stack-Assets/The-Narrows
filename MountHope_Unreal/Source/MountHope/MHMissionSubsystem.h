#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHMissionSubsystem.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FMHOnMissionCompleted, FString, Title, FString, CompletionMessage);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMHOnMissionFailed, FString, Reason);

UENUM(BlueprintType)
enum class EMHObjectiveType : uint8
{
    // Complete by satisfying the objective (reach the target / enter a vehicle /
    // finish the dialogue). Default; unchanged legacy behavior.
    Reach UMETA(DisplayName = "Reach"),
    // Same as Reach, but the step must be completed before TimeLimitSeconds
    // elapses or the mission fails and restarts from its first step.
    Timed UMETA(DisplayName = "Timed"),
    // Stay alive for TimeLimitSeconds; the step auto-completes when the timer
    // runs out (a "hold out" beat). No world target needed.
    Survive UMETA(DisplayName = "Survive")
};

USTRUCT(BlueprintType)
struct FMHMissionStep
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString Text;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    EMHObjectiveType ObjectiveType = EMHObjectiveType::Reach;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    float TimeLimitSeconds = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FVector Target = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    float Radius = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    bool bNeedVehicle = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 Reward = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    bool bIsCrime = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 CrimeSeverity = 10;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FGameplayTag ReputationFactionTag;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 ReputationDelta = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    bool bRequireNoHeat = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString WeatherOnStart;
};

USTRUCT(BlueprintType)
struct FMHMission
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString Title;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString Act;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    TArray<FMHMissionStep> Steps;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 CompletionReward = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    FString CompletionMessage;
};

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHMissionSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Mission")
    FMHOnMissionCompleted OnMissionCompleted;

    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Mission")
    FMHOnMissionFailed OnMissionFailed;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    TArray<FMHMission> Missions;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 MissionIndex = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    int32 StepIndex = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Mission")
    bool bCampaignComplete = false;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool LoadMissionsFromJson(const FString& RelativeOrAbsolutePath);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    void ResetCampaign();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    bool AdvanceStep();

    // Reset progress to the first step of the current mission (a checkpoint at
    // mission start), used when a mission is failed.
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Mission")
    void RestartCurrentMission();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Mission")
    bool IsMissionInProgress() const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Mission")
    bool GetCurrentMission(FMHMission& OutMission) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Mission")
    bool GetCurrentStep(FMHMissionStep& OutStep) const;
};
