// Automation tests for UMHTimeOfDaySubsystem clock rollover + sun curve.
// Pure logic on a NewObject subsystem. See Docs/ARCHITECTURE.md.

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "MHTimeOfDaySubsystem.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHTimeRolloverTest,
    "MountHope.TimeOfDay.HourWrapsPastMidnight",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHTimeRolloverTest::RunTest(const FString& Parameters)
{
    UMHTimeOfDaySubsystem* Time = NewObject<UMHTimeOfDaySubsystem>();
    if (!TestNotNull(TEXT("time-of-day subsystem constructed"), Time))
    {
        return false;
    }

    // 24 real seconds == one game day, so 1 real second advances one game hour.
    Time->RealSecondsPerGameDay = 24.0f;
    Time->CurrentHour = 23.5f;
    Time->AdvanceTime(1.0f);

    const float Hour = Time->GetCurrentHour();
    TestTrue(TEXT("hour stays within a single day"), Hour >= 0.0f && Hour < 24.0f);
    TestTrue(TEXT("advancing past midnight wraps to the early morning"), Hour < 1.0f);

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHSunCurveTest,
    "MountHope.TimeOfDay.SunIntensityDayVsNight",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHSunCurveTest::RunTest(const FString& Parameters)
{
    UMHTimeOfDaySubsystem* Time = NewObject<UMHTimeOfDaySubsystem>();
    if (!TestNotNull(TEXT("time-of-day subsystem constructed"), Time))
    {
        return false;
    }

    Time->CurrentHour = 12.0f;
    TestTrue(TEXT("midday is full sun"), Time->GetSunIntensityMultiplier() > 0.99f);
    TestFalse(TEXT("midday is not night"), Time->IsNight());

    Time->CurrentHour = 3.0f;
    TestTrue(TEXT("pre-dawn is dim"), Time->GetSunIntensityMultiplier() < 0.2f);
    TestTrue(TEXT("pre-dawn is night"), Time->IsNight());

    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
