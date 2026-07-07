// Automation tests for UMHGameStateSubsystem economy + consequence logic.
// Pure logic on a NewObject subsystem. See Docs/ARCHITECTURE.md.

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "MHGameStateSubsystem.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHCashClampTest,
    "MountHope.Economy.CashNeverGoesNegative",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHCashClampTest::RunTest(const FString& Parameters)
{
    UMHGameStateSubsystem* State = NewObject<UMHGameStateSubsystem>();
    if (!TestNotNull(TEXT("game state subsystem constructed"), State))
    {
        return false;
    }

    State->Cash = 100;
    State->AddCash(-500);
    TestEqual(TEXT("cash clamps at zero"), State->Cash, 0);

    State->AddCash(250);
    TestEqual(TEXT("cash accumulates"), State->Cash, 250);

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHBuyBusinessTest,
    "MountHope.Economy.BuyBusinessAndPassiveIncome",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHBuyBusinessTest::RunTest(const FString& Parameters)
{
    UMHGameStateSubsystem* State = NewObject<UMHGameStateSubsystem>();
    if (!TestNotNull(TEXT("game state subsystem constructed"), State))
    {
        return false;
    }

    FMHBusinessRecord Business;
    Business.Id = TEXT("dockbar");
    Business.Cost = 200;
    Business.DailyIncome = 50;
    State->Businesses.Add(Business);
    State->Cash = 250;

    TestTrue(TEXT("buying an affordable, unowned business succeeds"), State->BuyBusiness(TEXT("dockbar")));
    TestEqual(TEXT("purchase deducts the cost"), State->Cash, 50);
    TestEqual(TEXT("owned business yields passive daily income"), State->GetPassiveDailyIncome(), 50);

    TestFalse(TEXT("cannot buy the same business twice"), State->BuyBusiness(TEXT("dockbar")));
    TestFalse(TEXT("cannot buy an unknown business"), State->BuyBusiness(TEXT("nonexistent")));

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHWastedConsequenceTest,
    "MountHope.Consequence.LethalDamageTriggersWasted",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHWastedConsequenceTest::RunTest(const FString& Parameters)
{
    UMHGameStateSubsystem* State = NewObject<UMHGameStateSubsystem>();
    if (!TestNotNull(TEXT("game state subsystem constructed"), State))
    {
        return false;
    }

    State->Health = 100.0f;
    State->Cash = 1000;
    State->WastedCashPenalty = 200;

    State->ApplyDamage(150.0f);
    TestEqual(TEXT("health is restored after being wasted"), State->Health, 100.0f);
    TestEqual(TEXT("the wasted cash penalty is applied"), State->Cash, 800);

    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHArmorAbsorbsDamageTest,
    "MountHope.Combat.ArmorAbsorbsBeforeHealth",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHArmorAbsorbsDamageTest::RunTest(const FString& Parameters)
{
    UMHGameStateSubsystem* State = NewObject<UMHGameStateSubsystem>();
    if (!TestNotNull(TEXT("game state subsystem constructed"), State))
    {
        return false;
    }

    State->Health = 100.0f;
    State->Armor = 50.0f;

    State->ApplyDamage(30.0f);
    TestEqual(TEXT("armor soaks damage while it lasts"), State->Armor, 20.0f);
    TestEqual(TEXT("health is untouched while armor remains"), State->Health, 100.0f);

    State->ApplyDamage(40.0f);
    TestEqual(TEXT("armor is depleted"), State->Armor, 0.0f);
    TestEqual(TEXT("overflow damage carries through to health"), State->Health, 80.0f);

    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
