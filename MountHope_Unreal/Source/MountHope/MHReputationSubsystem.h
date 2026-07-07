#pragma once

#include "CoreMinimal.h"
#include "GameplayTagContainer.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHReputationSubsystem.generated.h"

UCLASS()
class MOUNTHOPE_API UMHReputationSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Reputation")
    void AddReputation(FGameplayTag FactionTag, int32 Delta);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Reputation")
    int32 GetReputation(FGameplayTag FactionTag) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Reputation")
    bool MeetsReputation(FGameplayTag FactionTag, int32 RequiredValue) const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    void GetReputationSnapshot(TMap<FString, int32>& OutSnapshot) const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    void RestoreReputationSnapshot(const TMap<FString, int32>& Snapshot);

private:
    UPROPERTY()
    TMap<FGameplayTag, int32> ReputationByFaction;
};
