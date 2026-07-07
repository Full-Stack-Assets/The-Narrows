#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHSaveSubsystem.generated.h"

class UMHSaveGame;

// NOT the active save path. UMHGameStateSubsystem::SaveToSlot/LoadFromSlot (slot
// UMHGameInstance::SaveSlotName, default "MountHopeSlot") is the real persistence path used by
// AMHGameModeBase and every gameplay system. This subsystem is unwired scaffolding left over from
// an earlier pass; DefaultSlotName below is kept identical to that real slot on purpose so that if
// something is ever pointed at this class instead, it reads/writes the same save rather than
// silently diverging into a second save file.
UCLASS()
class MOUNTHOPE_API UMHSaveSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    UMHSaveGame* CreateNewGameState();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    UMHSaveGame* LoadGameState();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    bool SaveGameState(UMHSaveGame* SaveGame);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Save")
    FString GetDefaultSlotName() const;

private:
    UPROPERTY()
    FString DefaultSlotName = TEXT("MountHopeSlot");

    UPROPERTY()
    int32 DefaultUserIndex = 0;
};
