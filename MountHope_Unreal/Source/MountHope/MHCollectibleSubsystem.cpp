#include "MHCollectibleSubsystem.h"

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
FString ResolvePath(const FString& RelativeOrAbsolutePath)
{
    if (FPaths::FileExists(RelativeOrAbsolutePath))
    {
        return RelativeOrAbsolutePath;
    }

    return FPaths::ConvertRelativePathToFull(FPaths::ProjectDir() / RelativeOrAbsolutePath);
}
}

bool UMHCollectibleSubsystem::LoadCollectiblesFromJson(const FString& RelativeOrAbsolutePath)
{
    const FString FullPath = ResolvePath(RelativeOrAbsolutePath);
    FString RawJson;
    if (!FFileHelper::LoadFileToString(RawJson, *FullPath))
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Unable to load collectibles JSON: %s"), *FullPath);
        return false;
    }

    TSharedPtr<FJsonObject> RootObject;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(RawJson);
    if (!FJsonSerializer::Deserialize(Reader, RootObject) || !RootObject.IsValid())
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Invalid collectibles JSON: %s"), *FullPath);
        return false;
    }

    const TArray<TSharedPtr<FJsonValue>>* CollectiblesArray = nullptr;
    if (!RootObject->TryGetArrayField(TEXT("collectibles"), CollectiblesArray) || !CollectiblesArray)
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Missing 'collectibles' field in %s"), *FullPath);
        return false;
    }

    Collectibles.Reset();
    Collectibles.Reserve(CollectiblesArray->Num());
    for (const TSharedPtr<FJsonValue>& Value : *CollectiblesArray)
    {
        const TSharedPtr<FJsonObject> Object = Value->AsObject();
        if (!Object.IsValid())
        {
            continue;
        }

        FString IdString;
        if (!Object->TryGetStringField(TEXT("id"), IdString) || IdString.IsEmpty())
        {
            UE_LOG(LogTemp, Warning, TEXT("MountHope: Skipping collectible entry with missing/empty id"));
            continue;
        }

        FString DisplayName;
        if (!Object->TryGetStringField(TEXT("name"), DisplayName) || DisplayName.IsEmpty())
        {
            UE_LOG(LogTemp, Warning, TEXT("MountHope: Skipping collectible '%s' with missing/empty name"), *IdString);
            continue;
        }

        FMHCollectibleRecord Record;
        Record.Id = FName(*IdString);
        Record.DisplayName = DisplayName;
        Object->TryGetStringField(TEXT("flavor"), Record.FlavorText);

        int32 Reward = Record.CashReward;
        if (Object->TryGetNumberField(TEXT("cashReward"), Reward))
        {
            Record.CashReward = Reward;
        }

        const TArray<TSharedPtr<FJsonValue>>* Pos = nullptr;
        if (Object->TryGetArrayField(TEXT("pos"), Pos) && Pos && Pos->Num() >= 3)
        {
            Record.WorldLocation = FVector(
                static_cast<float>((*Pos)[0]->AsNumber()),
                static_cast<float>((*Pos)[1]->AsNumber()),
                static_cast<float>((*Pos)[2]->AsNumber()));
        }

        if (!Record.Id.IsNone())
        {
            Collectibles.Add(MoveTemp(Record));
        }
    }

    UE_LOG(LogTemp, Log, TEXT("MountHope: Loaded %d collectibles"), Collectibles.Num());
    return Collectibles.Num() > 0;
}

bool UMHCollectibleSubsystem::CollectItem(FName ItemId)
{
    if (ItemId.IsNone() || CollectedIds.Contains(ItemId))
    {
        return false;
    }

    FMHCollectibleRecord Record;
    if (!FindCollectible(ItemId, Record))
    {
        return false;
    }

    CollectedIds.Add(ItemId);
    OnCollectibleFound.Broadcast(ItemId, GetCollectedCount(), GetTotalCount());
    return true;
}

bool UMHCollectibleSubsystem::IsCollected(FName ItemId) const
{
    return CollectedIds.Contains(ItemId);
}

bool UMHCollectibleSubsystem::FindCollectible(FName ItemId, FMHCollectibleRecord& OutRecord) const
{
    for (const FMHCollectibleRecord& Record : Collectibles)
    {
        if (Record.Id == ItemId)
        {
            OutRecord = Record;
            return true;
        }
    }

    return false;
}

TArray<FString> UMHCollectibleSubsystem::GetCollectedIdsAsStrings() const
{
    TArray<FString> Result;
    Result.Reserve(CollectedIds.Num());
    for (const FName& Id : CollectedIds)
    {
        Result.Add(Id.ToString());
    }

    return Result;
}

void UMHCollectibleSubsystem::RestoreCollectedIds(const TArray<FString>& SavedIds)
{
    CollectedIds.Reset();
    for (const FString& Id : SavedIds)
    {
        if (!Id.IsEmpty())
        {
            CollectedIds.Add(FName(*Id));
        }
    }
}
