#pragma once

#include "CoreMinimal.h"
#include "GameFramework/SaveGame.h"
#include "MHSaveGame.generated.h"

UCLASS()
class MOUNTHOPE_API UMHSaveGame : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    int32 Cash = 250;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    float Health = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    float Armor = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    float PoliceHeat = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    float FactionHeat = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    uint8 Weather = 0;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    TArray<FString> OwnedBusinessIds;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    bool bHasSafehouse = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    FVector SafehouseLocation = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    TArray<FString> CollectedCollectibleIds;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Mount Hope|Save")
    TMap<FString, int32> ReputationByFaction;
};
