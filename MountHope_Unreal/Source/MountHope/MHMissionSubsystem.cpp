#include "MHMissionSubsystem.h"

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
FString ResolvePath(const FString& RelativeOrAbsolutePath)
{
    if (FPaths::FileExists(RelativeOrAbsolutePath))
    {
        return RelativeOrAbsolutePath;
    }

    return FPaths::ConvertRelativePathToFull(FPaths::ProjectDir() / RelativeOrAbsolutePath);
}
}

bool UMHMissionSubsystem::LoadMissionsFromJson(const FString& RelativeOrAbsolutePath)
{
    const FString FullPath = ResolvePath(RelativeOrAbsolutePath);
    FString RawJson;
    if (!FFileHelper::LoadFileToString(RawJson, *FullPath))
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Unable to load mission JSON: %s"), *FullPath);
        return false;
    }

    TSharedPtr<FJsonObject> RootObject;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(RawJson);
    if (!FJsonSerializer::Deserialize(Reader, RootObject) || !RootObject.IsValid())
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Invalid mission JSON: %s"), *FullPath);
        return false;
    }

    const TArray<TSharedPtr<FJsonValue>>* MissionsArray = nullptr;
    if (!RootObject->TryGetArrayField(TEXT("missions"), MissionsArray) || !MissionsArray)
    {
        return false;
    }

    Missions.Reset();
    for (const TSharedPtr<FJsonValue>& MissionValue : *MissionsArray)
    {
        const TSharedPtr<FJsonObject> MissionObject = MissionValue->AsObject();
        if (!MissionObject.IsValid())
        {
            continue;
        }

        FString Title;
        if (!MissionObject->TryGetStringField(TEXT("title"), Title) || Title.IsEmpty())
        {
            UE_LOG(LogTemp, Warning, TEXT("MountHope: Skipping mission entry with missing/empty title"));
            continue;
        }

        FMHMission Mission;
        Mission.Title = Title;
        MissionObject->TryGetStringField(TEXT("act"), Mission.Act);
        MissionObject->TryGetStringField(TEXT("completionMessage"), Mission.CompletionMessage);

        int32 CompletionRewardValue = Mission.CompletionReward;
        if (MissionObject->TryGetNumberField(TEXT("completionReward"), CompletionRewardValue))
        {
            Mission.CompletionReward = CompletionRewardValue;
        }

        const TArray<TSharedPtr<FJsonValue>>* StepsArray = nullptr;
        if (MissionObject->TryGetArrayField(TEXT("steps"), StepsArray) && StepsArray)
        {
            for (const TSharedPtr<FJsonValue>& StepValue : *StepsArray)
            {
                const TSharedPtr<FJsonObject> StepObject = StepValue->AsObject();
                if (!StepObject.IsValid())
                {
                    continue;
                }

                FString StepText;
                if (!StepObject->TryGetStringField(TEXT("text"), StepText) || StepText.IsEmpty())
                {
                    UE_LOG(LogTemp, Warning, TEXT("MountHope: Skipping mission step with missing/empty text"));
                    continue;
                }

                FMHMissionStep Step;
                Step.Text = StepText;
                Step.Radius = static_cast<float>(StepObject->GetNumberField(TEXT("radius")));

                FString ObjectiveTypeString;
                if (StepObject->TryGetStringField(TEXT("objectiveType"), ObjectiveTypeString))
                {
                    if (ObjectiveTypeString.Equals(TEXT("timed"), ESearchCase::IgnoreCase))
                    {
                        Step.ObjectiveType = EMHObjectiveType::Timed;
                    }
                    else if (ObjectiveTypeString.Equals(TEXT("survive"), ESearchCase::IgnoreCase))
                    {
                        Step.ObjectiveType = EMHObjectiveType::Survive;
                    }
                    else
                    {
                        Step.ObjectiveType = EMHObjectiveType::Reach;
                    }
                }

                double TimeLimitValue = Step.TimeLimitSeconds;
                if (StepObject->TryGetNumberField(TEXT("timeLimitSeconds"), TimeLimitValue))
                {
                    Step.TimeLimitSeconds = static_cast<float>(TimeLimitValue);
                }

                Step.bNeedVehicle = StepObject->GetBoolField(TEXT("needVehicle"));
                Step.Reward = StepObject->GetIntegerField(TEXT("reward"));

                if (StepObject->HasField(TEXT("crime")))
                {
                    Step.bIsCrime = StepObject->GetBoolField(TEXT("crime"));
                }

                int32 CrimeSeverityValue = Step.CrimeSeverity;
                if (StepObject->TryGetNumberField(TEXT("crimeSeverity"), CrimeSeverityValue))
                {
                    Step.CrimeSeverity = CrimeSeverityValue;
                }

                FString FactionTagString;
                if (StepObject->TryGetStringField(TEXT("reputationFaction"), FactionTagString) && !FactionTagString.IsEmpty())
                {
                    Step.ReputationFactionTag = FGameplayTag::RequestGameplayTag(FName(*FactionTagString), false);
                }

                int32 ReputationDeltaValue = Step.ReputationDelta;
                if (StepObject->TryGetNumberField(TEXT("reputationDelta"), ReputationDeltaValue))
                {
                    Step.ReputationDelta = ReputationDeltaValue;
                }

                if (StepObject->HasField(TEXT("requireNoHeat")))
                {
                    Step.bRequireNoHeat = StepObject->GetBoolField(TEXT("requireNoHeat"));
                }

                StepObject->TryGetStringField(TEXT("weatherOnStart"), Step.WeatherOnStart);

                const TArray<TSharedPtr<FJsonValue>>* TargetArray = nullptr;
                if (StepObject->TryGetArrayField(TEXT("target"), TargetArray) && TargetArray && TargetArray->Num() >= 3)
                {
                    Step.Target = FVector(
                        static_cast<float>((*TargetArray)[0]->AsNumber()),
                        static_cast<float>((*TargetArray)[1]->AsNumber()),
                        static_cast<float>((*TargetArray)[2]->AsNumber()));
                }

                Mission.Steps.Add(MoveTemp(Step));
            }
        }

        if (Mission.Steps.Num() > 0)
        {
            Missions.Add(MoveTemp(Mission));
        }
    }

    ResetCampaign();
    UE_LOG(LogTemp, Log, TEXT("MountHope: Loaded %d missions"), Missions.Num());
    return Missions.Num() > 0;
}

void UMHMissionSubsystem::ResetCampaign()
{
    MissionIndex = 0;
    StepIndex = 0;
    bCampaignComplete = Missions.Num() == 0;
}

bool UMHMissionSubsystem::AdvanceStep()
{
    if (bCampaignComplete || Missions.Num() == 0 || !Missions.IsValidIndex(MissionIndex))
    {
        return false;
    }

    const FMHMission& Mission = Missions[MissionIndex];
    if (!Mission.Steps.IsValidIndex(StepIndex))
    {
        return false;
    }

    ++StepIndex;
    if (Mission.Steps.IsValidIndex(StepIndex))
    {
        return true;
    }

    ++MissionIndex;
    StepIndex = 0;
    bCampaignComplete = !Missions.IsValidIndex(MissionIndex);
    return true;
}

void UMHMissionSubsystem::RestartCurrentMission()
{
    if (Missions.IsValidIndex(MissionIndex))
    {
        StepIndex = 0;
    }
}

bool UMHMissionSubsystem::IsMissionInProgress() const
{
    if (bCampaignComplete || !Missions.IsValidIndex(MissionIndex))
    {
        return false;
    }
    return Missions[MissionIndex].Steps.IsValidIndex(StepIndex);
}

bool UMHMissionSubsystem::GetCurrentMission(FMHMission& OutMission) const
{
    if (Missions.IsValidIndex(MissionIndex))
    {
        OutMission = Missions[MissionIndex];
        return true;
    }
    return false;
}

bool UMHMissionSubsystem::GetCurrentStep(FMHMissionStep& OutStep) const
{
    if (!Missions.IsValidIndex(MissionIndex))
    {
        return false;
    }

    const FMHMission& Mission = Missions[MissionIndex];
    if (Mission.Steps.IsValidIndex(StepIndex))
    {
        OutStep = Mission.Steps[StepIndex];
        return true;
    }

    return false;
}
