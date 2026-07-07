// Automation tests for UMHWantedSubsystem's heat/decay logic.
//
// These run in the editor's Automation window (Session Frontend) or headlessly
// via:  UnrealEditor-Cmd MountHope.uproject -ExecCmds="Automation RunTests MountHope; Quit" -unattended -nop4
// They exercise pure, world-independent logic, so each test drives a
// NewObject-constructed subsystem directly. See Docs/ARCHITECTURE.md.

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "MHWantedSubsystem.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHWantedHeatDecayTest,
    "MountHope.Wanted.HeatDecaysAtNormalFramerate",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHWantedHeatDecayTest::RunTest(const FString& Parameters)
{
    UMHWantedSubsystem* Wanted = NewObject<UMHWantedSubsystem>();
    if (!TestNotNull(TEXT("wanted subsystem constructed"), Wanted))
    {
        return false;
    }

    Wanted->ReportCrime(EMHCrimeType::Assault, 20);
    const int32 HeatAfterCrime = Wanted->GetHeat();
    TestTrue(TEXT("committing a crime raises heat"), HeatAfterCrime > 0);

    // Regression guard: the decay used to RoundToInt(rate * dt) every frame, which
    // truncates to 0 at any real framerate, so heat never dropped. Drive ~12s at
    // 60 FPS (past the decay delay) and require a measurable drop.
    for (int32 Frame = 0; Frame < 60 * 12; ++Frame)
    {
        Wanted->TickWantedDecay(1.0f / 60.0f);
    }
    TestTrue(TEXT("heat decays below its post-crime value at 60 FPS"), Wanted->GetHeat() < HeatAfterCrime);

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHWantedLevelClampTest,
    "MountHope.Wanted.WantedLevelClampsToFiveStars",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHWantedLevelClampTest::RunTest(const FString& Parameters)
{
    UMHWantedSubsystem* Wanted = NewObject<UMHWantedSubsystem>();
    if (!TestNotNull(TEXT("wanted subsystem constructed"), Wanted))
    {
        return false;
    }

    for (int32 i = 0; i < 20; ++i)
    {
        Wanted->ReportCrime(EMHCrimeType::Assault, 25);
    }
    TestTrue(TEXT("wanted level never exceeds 5 stars"), Wanted->GetWantedLevel() <= 5);
    TestTrue(TEXT("police are searching at high heat"), Wanted->IsPoliceSearching());

    Wanted->ClearWantedState();
    TestEqual(TEXT("clearing wanted state zeroes the level"), Wanted->GetWantedLevel(), 0);
    TestEqual(TEXT("clearing wanted state zeroes heat"), Wanted->GetHeat(), 0);

    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
