// Automation tests for UMHMissionSubsystem step/mission progression, including
// the failure/restart additions. Pure logic — drives a NewObject subsystem with
// a hand-built campaign. See Docs/ARCHITECTURE.md.

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "MHMissionSubsystem.h"

#if WITH_DEV_AUTOMATION_TESTS

namespace
{
UMHMissionSubsystem* MakeTwoStepCampaign()
{
    UMHMissionSubsystem* Missions = NewObject<UMHMissionSubsystem>();
    if (!Missions)
    {
        return nullptr;
    }

    FMHMission Mission;
    Mission.Title = TEXT("Test Mission");
    FMHMissionStep StepA;
    StepA.Text = TEXT("Step A");
    FMHMissionStep StepB;
    StepB.Text = TEXT("Step B");
    Mission.Steps.Add(StepA);
    Mission.Steps.Add(StepB);
    Missions->Missions.Add(Mission);
    Missions->ResetCampaign();
    return Missions;
}
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHMissionAdvanceTest,
    "MountHope.Mission.StepsAdvanceAndCampaignCompletes",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHMissionAdvanceTest::RunTest(const FString& Parameters)
{
    UMHMissionSubsystem* Missions = MakeTwoStepCampaign();
    if (!TestNotNull(TEXT("mission subsystem constructed"), Missions))
    {
        return false;
    }

    TestTrue(TEXT("mission is in progress at start"), Missions->IsMissionInProgress());
    TestEqual(TEXT("starts at step 0"), Missions->StepIndex, 0);

    Missions->AdvanceStep();
    TestEqual(TEXT("advances to step 1"), Missions->StepIndex, 1);

    Missions->AdvanceStep();
    TestTrue(TEXT("campaign completes after the final step"), Missions->bCampaignComplete);
    TestFalse(TEXT("no mission in progress once the campaign is complete"), Missions->IsMissionInProgress());

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHMissionRestartTest,
    "MountHope.Mission.RestartReturnsToFirstStep",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHMissionRestartTest::RunTest(const FString& Parameters)
{
    UMHMissionSubsystem* Missions = MakeTwoStepCampaign();
    if (!TestNotNull(TEXT("mission subsystem constructed"), Missions))
    {
        return false;
    }

    Missions->AdvanceStep();
    TestEqual(TEXT("progressed off the first step"), Missions->StepIndex, 1);

    Missions->RestartCurrentMission();
    TestEqual(TEXT("restart returns to the first step"), Missions->StepIndex, 0);
    TestTrue(TEXT("mission is in progress again after restart"), Missions->IsMissionInProgress());

    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
