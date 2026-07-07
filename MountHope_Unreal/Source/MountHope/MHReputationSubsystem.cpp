#include "MHReputationSubsystem.h"

void UMHReputationSubsystem::AddReputation(FGameplayTag FactionTag, int32 Delta)
{
    if (!FactionTag.IsValid() || Delta == 0)
    {
        return;
    }

    int32& Reputation = ReputationByFaction.FindOrAdd(FactionTag);
    Reputation = FMath::Clamp(Reputation + Delta, -100, 100);
}

int32 UMHReputationSubsystem::GetReputation(FGameplayTag FactionTag) const
{
    const int32* Reputation = ReputationByFaction.Find(FactionTag);
    return Reputation != nullptr ? *Reputation : 0;
}

bool UMHReputationSubsystem::MeetsReputation(FGameplayTag FactionTag, int32 RequiredValue) const
{
    return GetReputation(FactionTag) >= RequiredValue;
}

void UMHReputationSubsystem::GetReputationSnapshot(TMap<FString, int32>& OutSnapshot) const
{
    OutSnapshot.Reset();
    for (const TPair<FGameplayTag, int32>& Pair : ReputationByFaction)
    {
        OutSnapshot.Add(Pair.Key.ToString(), Pair.Value);
    }
}

void UMHReputationSubsystem::RestoreReputationSnapshot(const TMap<FString, int32>& Snapshot)
{
    ReputationByFaction.Reset();
    for (const TPair<FString, int32>& Pair : Snapshot)
    {
        const FGameplayTag Tag = FGameplayTag::RequestGameplayTag(FName(*Pair.Key), /*ErrorIfNotFound=*/false);
        if (Tag.IsValid())
        {
            ReputationByFaction.Add(Tag, Pair.Value);
        }
    }
}
