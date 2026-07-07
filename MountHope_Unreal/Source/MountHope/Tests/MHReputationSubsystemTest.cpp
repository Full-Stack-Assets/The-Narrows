// Automation tests for UMHReputationSubsystem clamping + save snapshot roundtrip.
// Uses gameplay tags, so it runs in editor context where DefaultGameplayTags.ini
// is loaded; if a tag isn't registered the reputation assertions are skipped with
// a warning rather than failing spuriously. See Docs/ARCHITECTURE.md.

#include "CoreMinimal.h"
#include "Misc/AutomationTest.h"
#include "GameplayTagContainer.h"
#include "MHReputationSubsystem.h"

#if WITH_DEV_AUTOMATION_TESTS

IMPLEMENT_SIMPLE_AUTOMATION_TEST(
    FMHReputationClampAndSnapshotTest,
    "MountHope.Reputation.ClampsAndSurvivesSnapshotRoundtrip",
    EAutomationTestFlags::EditorContext | EAutomationTestFlags::EngineFilter)

bool FMHReputationClampAndSnapshotTest::RunTest(const FString& Parameters)
{
    UMHReputationSubsystem* Reputation = NewObject<UMHReputationSubsystem>();
    if (!TestNotNull(TEXT("reputation subsystem constructed"), Reputation))
    {
        return false;
    }

    const FGameplayTag Faction = FGameplayTag::RequestGameplayTag(FName(TEXT("Faction.Crew.Dockside")), /*ErrorIfNotFound=*/false);
    if (!Faction.IsValid())
    {
        AddWarning(TEXT("Faction.Crew.Dockside is not registered in this context; skipping reputation assertions."));
        return true;
    }

    Reputation->AddReputation(Faction, 60);
    Reputation->AddReputation(Faction, 60);
    TestEqual(TEXT("reputation clamps at +100"), Reputation->GetReputation(Faction), 100);
    TestTrue(TEXT("meets a threshold at or below the current value"), Reputation->MeetsReputation(Faction, 50));

    Reputation->AddReputation(Faction, -500);
    TestEqual(TEXT("reputation clamps at -100"), Reputation->GetReputation(Faction), -100);

    Reputation->AddReputation(Faction, 150);
    TMap<FString, int32> Snapshot;
    Reputation->GetReputationSnapshot(Snapshot);

    UMHReputationSubsystem* Restored = NewObject<UMHReputationSubsystem>();
    if (!TestNotNull(TEXT("second reputation subsystem constructed"), Restored))
    {
        return false;
    }
    Restored->RestoreReputationSnapshot(Snapshot);
    TestEqual(TEXT("reputation survives a save/restore snapshot roundtrip"),
        Restored->GetReputation(Faction), Reputation->GetReputation(Faction));

    return true;
}

#endif // WITH_DEV_AUTOMATION_TESTS
