// Automation tests for police combat/escalation logic: unit health/death and the
// wanted-level tier map. Pure logic on NewObject instances (no world/BeginPlay).
// See Docs/ARCHITECTURE.md.

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "MHPoliceSpawnerActor.h"
#include "MHPoliceUnitPawn.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHPoliceUnitDeathTest,
    "MountHope.Police.UnitDiesWhenHealthDepleted",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHPoliceUnitDeathTest::RunTest(const FString& Parameters)
{
    AMHPoliceUnitPawn* Cop = NewObject<AMHPoliceUnitPawn>();
    if (!TestNotNull(TEXT("police unit constructed"), Cop))
    {
        return false;
    }

    Cop->ConfigureForTier(40.0f, /*bArmed=*/true);
    TestFalse(TEXT("a freshly configured unit is alive"), Cop->IsDead());

    Cop->ApplyDamage(25.0f);
    TestFalse(TEXT("survives non-lethal damage"), Cop->IsDead());

    Cop->ApplyDamage(25.0f);
    TestTrue(TEXT("dies once its health is depleted"), Cop->IsDead());

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHPoliceTierEscalationTest,
    "MountHope.Police.WantedTierEscalates",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHPoliceTierEscalationTest::RunTest(const FString& Parameters)
{
    AMHPoliceSpawnerActor* Spawner = NewObject<AMHPoliceSpawnerActor>();
    if (!TestNotNull(TEXT("police spawner constructed"), Spawner))
    {
        return false;
    }

    TestEqual(TEXT("no pursuers at zero stars"), Spawner->GetTierForWantedLevel(0).UnitCount, 0);
    TestEqual(TEXT("one pursuer per star"), Spawner->GetTierForWantedLevel(2).UnitCount, 2);
    TestEqual(TEXT("pursuer count caps at five stars"), Spawner->GetTierForWantedLevel(9).UnitCount, 5);

    TestFalse(TEXT("low wanted levels are unarmed"), Spawner->GetTierForWantedLevel(1).bArmed);
    TestTrue(TEXT("high wanted levels bring armed units"), Spawner->GetTierForWantedLevel(4).bArmed);

    TestTrue(TEXT("units get tougher as the wanted level rises"),
        Spawner->GetTierForWantedLevel(5).UnitHealth > Spawner->GetTierForWantedLevel(1).UnitHealth);

    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
