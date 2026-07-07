#include "MHGameStateSubsystem.h"

#include "Dom/JsonObject.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "MHCollectibleSubsystem.h"
#include "MHReputationSubsystem.h"
#include "MHSaveGame.h"
#include "MHWantedSubsystem.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
void ClearWantedStateForGameInstance(const UGameInstance* GameInstance)
{
    const UWorld* World = GameInstance ? GameInstance->GetWorld() : nullptr;
    if (UMHWantedSubsystem* Wanted = World ? World->GetSubsystem<UMHWantedSubsystem>() : nullptr)
    {
        Wanted->ClearWantedState();
    }
}
}

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

float ClampHeat(float Value)
{
    return FMath::Clamp(Value, 0.0f, 5.0f);
}
}

void UMHGameStateSubsystem::AddHeat(float PoliceDelta, float FactionDelta)
{
    PoliceHeat = ClampHeat(PoliceHeat + PoliceDelta);
    FactionHeat = ClampHeat(FactionHeat + FactionDelta);
}

void UMHGameStateSubsystem::DecayHeat(float DeltaSeconds, float RatePerSecond)
{
    if (PoliceHeat <= 0.0f && FactionHeat <= 0.0f)
    {
        return;
    }

    const float Decay = DeltaSeconds * RatePerSecond;
    PoliceHeat = ClampHeat(PoliceHeat - Decay);
    FactionHeat = ClampHeat(FactionHeat - Decay);
}

void UMHGameStateSubsystem::AddCash(int32 Delta)
{
    Cash = FMath::Max(0, Cash + Delta);
}

void UMHGameStateSubsystem::ApplyDamage(float Damage)
{
    const bool bWasAlive = Health > 0.0f;

    // Armor soaks damage first (classic GTA), health takes only the overflow.
    float Remaining = FMath::Max(0.0f, Damage);
    if (Armor > 0.0f)
    {
        const float Absorbed = FMath::Min(Armor, Remaining);
        Armor -= Absorbed;
        Remaining -= Absorbed;
    }

    Health = FMath::Clamp(Health - Remaining, 0.0f, 100.0f);

    if (bWasAlive && Health <= 0.0f)
    {
        AddCash(-WastedCashPenalty);
        Health = 100.0f;
        Armor = 0.0f;
        ClearWantedStateForGameInstance(GetGameInstance());
        OnPlayerWasted.Broadcast();
    }
}

void UMHGameStateSubsystem::Heal(float Amount)
{
    Health = FMath::Clamp(Health + FMath::Max(0.0f, Amount), 0.0f, 100.0f);
}

void UMHGameStateSubsystem::AddArmor(float Amount)
{
    Armor = FMath::Clamp(Armor + Amount, 0.0f, MaxArmor);
}

void UMHGameStateSubsystem::TriggerBusted()
{
    AddCash(-BustedCashPenalty);
    Health = 100.0f;
    Armor = 0.0f;
    ClearWantedStateForGameInstance(GetGameInstance());
    OnPlayerBusted.Broadcast();
}

void UMHGameStateSubsystem::CycleWeather()
{
    switch (Weather)
    {
    case EMHWeatherState::Clear:
        SetWeather(EMHWeatherState::DenseFog);
        break;
    case EMHWeatherState::DenseFog:
        SetWeather(EMHWeatherState::CoastalRain);
        break;
    case EMHWeatherState::CoastalRain:
        SetWeather(EMHWeatherState::Noreaster);
        break;
    default:
        SetWeather(EMHWeatherState::Clear);
        break;
    }
}

void UMHGameStateSubsystem::SetWeather(EMHWeatherState NewWeather)
{
    if (Weather == NewWeather)
    {
        return;
    }

    Weather = NewWeather;
    OnWeatherChanged.Broadcast(Weather);
}

bool UMHGameStateSubsystem::BuyBusiness(const FString& BusinessId)
{
    for (const FMHBusinessRecord& Business : Businesses)
    {
        if (Business.Id == BusinessId)
        {
            const FName Key(*Business.Id);
            if (OwnedBusinessIds.Contains(Key) || Cash < Business.Cost)
            {
                return false;
            }

            OwnedBusinessIds.Add(Key);
            AddCash(-Business.Cost);
            return true;
        }
    }

    return false;
}

void UMHGameStateSubsystem::SetSafehouseLocation(const FVector& NewLocation)
{
    bHasSafehouse = true;
    SafehouseLocation = NewLocation;
}

int32 UMHGameStateSubsystem::GetPassiveDailyIncome() const
{
    int32 Total = 0;
    for (const FMHBusinessRecord& Business : Businesses)
    {
        if (OwnedBusinessIds.Contains(FName(*Business.Id)))
        {
            Total += Business.DailyIncome;
        }
    }
    return Total;
}

bool UMHGameStateSubsystem::LoadBusinessesFromJson(const FString& RelativeOrAbsolutePath)
{
    const FString FullPath = ResolvePath(RelativeOrAbsolutePath);
    FString RawJson;
    if (!FFileHelper::LoadFileToString(RawJson, *FullPath))
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Unable to load businesses JSON: %s"), *FullPath);
        return false;
    }

    TSharedPtr<FJsonObject> RootObject;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(RawJson);
    if (!FJsonSerializer::Deserialize(Reader, RootObject) || !RootObject.IsValid())
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Invalid businesses JSON: %s"), *FullPath);
        return false;
    }

    const TArray<TSharedPtr<FJsonValue>>* BusinessesArray = nullptr;
    if (!RootObject->TryGetArrayField(TEXT("businesses"), BusinessesArray) || !BusinessesArray)
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Missing 'businesses' field in %s"), *FullPath);
        return false;
    }

    Businesses.Reset();
    Businesses.Reserve(BusinessesArray->Num());
    for (const TSharedPtr<FJsonValue>& Value : *BusinessesArray)
    {
        const TSharedPtr<FJsonObject> Object = Value->AsObject();
        if (!Object.IsValid())
        {
            continue;
        }

        FMHBusinessRecord Record;
        Record.Id = Object->GetStringField(TEXT("id"));
        Record.Name = Object->GetStringField(TEXT("name"));
        Record.Cost = Object->GetIntegerField(TEXT("cost"));
        Record.DailyIncome = Object->GetIntegerField(TEXT("dailyIncome"));

        const TArray<TSharedPtr<FJsonValue>>* Pos = nullptr;
        if (Object->TryGetArrayField(TEXT("pos"), Pos) && Pos && Pos->Num() >= 3)
        {
            Record.WorldLocation = FVector(
                static_cast<float>((*Pos)[0]->AsNumber()),
                static_cast<float>((*Pos)[1]->AsNumber()),
                static_cast<float>((*Pos)[2]->AsNumber()));
        }

        Businesses.Add(MoveTemp(Record));
    }

    UE_LOG(LogTemp, Log, TEXT("MountHope: Loaded %d businesses"), Businesses.Num());
    return Businesses.Num() > 0;
}

bool UMHGameStateSubsystem::SaveToSlot(const FString& SlotName, int32 UserIndex) const
{
    UMHSaveGame* Save = Cast<UMHSaveGame>(UGameplayStatics::CreateSaveGameObject(UMHSaveGame::StaticClass()));
    if (!Save)
    {
        return false;
    }

    Save->Cash = Cash;
    Save->Health = Health;
    Save->Armor = Armor;
    Save->PoliceHeat = PoliceHeat;
    Save->FactionHeat = FactionHeat;
    Save->Weather = static_cast<uint8>(Weather);

    Save->OwnedBusinessIds.Reset();
    Save->OwnedBusinessIds.Reserve(OwnedBusinessIds.Num());
    for (const FName& Id : OwnedBusinessIds)
    {
        Save->OwnedBusinessIds.Add(Id.ToString());
    }

    Save->bHasSafehouse = bHasSafehouse;
    Save->SafehouseLocation = SafehouseLocation;

    if (const UGameInstance* GameInstance = GetGameInstance())
    {
        if (const UMHCollectibleSubsystem* Collectibles = GameInstance->GetSubsystem<UMHCollectibleSubsystem>())
        {
            Save->CollectedCollectibleIds = Collectibles->GetCollectedIdsAsStrings();
        }

        if (const UMHReputationSubsystem* Reputation = GameInstance->GetSubsystem<UMHReputationSubsystem>())
        {
            Reputation->GetReputationSnapshot(Save->ReputationByFaction);
        }
    }

    return UGameplayStatics::SaveGameToSlot(Save, SlotName, UserIndex);
}

bool UMHGameStateSubsystem::LoadFromSlot(const FString& SlotName, int32 UserIndex)
{
    if (!UGameplayStatics::DoesSaveGameExist(SlotName, UserIndex))
    {
        return false;
    }

    UMHSaveGame* Save = Cast<UMHSaveGame>(UGameplayStatics::LoadGameFromSlot(SlotName, UserIndex));
    if (!Save)
    {
        return false;
    }

    Cash = FMath::Max(0, Save->Cash);
    Health = FMath::Clamp(Save->Health, 0.0f, 100.0f);
    Armor = FMath::Clamp(Save->Armor, 0.0f, MaxArmor);
    PoliceHeat = ClampHeat(Save->PoliceHeat);
    FactionHeat = ClampHeat(Save->FactionHeat);
    Weather = static_cast<EMHWeatherState>(FMath::Clamp<int32>(Save->Weather, 0, 3));
    OnWeatherChanged.Broadcast(Weather);

    OwnedBusinessIds.Reset();
    for (const FString& Id : Save->OwnedBusinessIds)
    {
        if (!Id.IsEmpty())
        {
            OwnedBusinessIds.Add(FName(*Id));
        }
    }

    bHasSafehouse = Save->bHasSafehouse;
    SafehouseLocation = Save->SafehouseLocation;

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHCollectibleSubsystem* Collectibles = GameInstance->GetSubsystem<UMHCollectibleSubsystem>())
        {
            Collectibles->RestoreCollectedIds(Save->CollectedCollectibleIds);
        }

        if (UMHReputationSubsystem* Reputation = GameInstance->GetSubsystem<UMHReputationSubsystem>())
        {
            Reputation->RestoreReputationSnapshot(Save->ReputationByFaction);
        }
    }

    return true;
}
