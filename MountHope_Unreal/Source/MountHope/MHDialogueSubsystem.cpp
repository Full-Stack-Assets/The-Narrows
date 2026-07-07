#include "MHDialogueSubsystem.h"

#include "Dom/JsonObject.h"
#include "MHGameModeBase.h"
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

bool UMHDialogueSubsystem::LoadDialogueFromJson(const FString& RelativeOrAbsolutePath)
{
    const FString FullPath = ResolvePath(RelativeOrAbsolutePath);
    FString RawJson;
    if (!FFileHelper::LoadFileToString(RawJson, *FullPath))
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Unable to load dialogue JSON: %s"), *FullPath);
        return false;
    }

    TSharedPtr<FJsonObject> RootObject;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(RawJson);
    if (!FJsonSerializer::Deserialize(Reader, RootObject) || !RootObject.IsValid())
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Invalid dialogue JSON: %s"), *FullPath);
        return false;
    }

    const TArray<TSharedPtr<FJsonValue>>* ConversationsArray = nullptr;
    if (!RootObject->TryGetArrayField(TEXT("conversations"), ConversationsArray) || !ConversationsArray)
    {
        return false;
    }

    Conversations.Reset();
    for (const TSharedPtr<FJsonValue>& ConversationValue : *ConversationsArray)
    {
        const TSharedPtr<FJsonObject> ConversationObject = ConversationValue->AsObject();
        if (!ConversationObject.IsValid())
        {
            continue;
        }

        FString ConversationIdString;
        if (!ConversationObject->TryGetStringField(TEXT("id"), ConversationIdString) || ConversationIdString.IsEmpty())
        {
            UE_LOG(LogTemp, Warning, TEXT("MountHope: Skipping dialogue conversation with missing/empty id"));
            continue;
        }

        FMHDialogueConversation Conversation;
        Conversation.ConversationId = FName(*ConversationIdString);
        ConversationObject->TryGetStringField(TEXT("speaker"), Conversation.Speaker);
        ConversationObject->TryGetStringField(TEXT("prompt"), Conversation.Prompt);

        const TArray<TSharedPtr<FJsonValue>>* LinesArray = nullptr;
        if (ConversationObject->TryGetArrayField(TEXT("lines"), LinesArray) && LinesArray)
        {
            for (const TSharedPtr<FJsonValue>& LineValue : *LinesArray)
            {
                FMHDialogueLine Line;
                if (LineValue->Type == EJson::String)
                {
                    Line.Text = LineValue->AsString();
                }
                else if (const TSharedPtr<FJsonObject> LineObject = LineValue->AsObject())
                {
                    Line.Text = LineObject->GetStringField(TEXT("text"));
                }

                if (!Line.Text.IsEmpty())
                {
                    Conversation.Lines.Add(MoveTemp(Line));
                }
            }
        }

        const TSharedPtr<FJsonObject>* OnCompleteObject = nullptr;
        if (ConversationObject->TryGetObjectField(TEXT("onComplete"), OnCompleteObject) && OnCompleteObject && OnCompleteObject->IsValid())
        {
            Conversation.OnComplete.bCompleteObjective = (*OnCompleteObject)->GetBoolField(TEXT("completeObjective"));
            if ((*OnCompleteObject)->HasField(TEXT("requireOnFoot")))
            {
                Conversation.OnComplete.bRequireOnFoot = (*OnCompleteObject)->GetBoolField(TEXT("requireOnFoot"));
            }
        }

        if (Conversation.ConversationId != NAME_None && Conversation.Lines.Num() > 0)
        {
            Conversations.Add(MoveTemp(Conversation));
        }
    }

    UE_LOG(LogTemp, Log, TEXT("MountHope: Loaded %d dialogue conversations"), Conversations.Num());
    return Conversations.Num() > 0;
}

bool UMHDialogueSubsystem::StartConversation(FName ConversationId)
{
    FMHDialogueConversation Conversation;
    if (!FindConversation(ConversationId, Conversation))
    {
        return false;
    }

    ActiveConversationId = ConversationId;
    ActiveLineIndex = 0;
    BroadcastCurrentLine();
    return true;
}

bool UMHDialogueSubsystem::AdvanceConversation(bool bPlayerInVehicle)
{
    if (!IsConversationActive())
    {
        return false;
    }

    FMHDialogueConversation Conversation;
    if (!GetActiveConversation(Conversation))
    {
        return false;
    }

    ++ActiveLineIndex;
    if (Conversation.Lines.IsValidIndex(ActiveLineIndex))
    {
        BroadcastCurrentLine();
        return true;
    }

    const FMHDialogueCompletion Completion = Conversation.OnComplete;
    const FName EndedId = ActiveConversationId;
    EndConversation();
    ApplyCompletion(Completion, bPlayerInVehicle);
    OnDialogueEnded.Broadcast(EndedId);
    return false;
}

void UMHDialogueSubsystem::EndConversation()
{
    ActiveConversationId = NAME_None;
    ActiveLineIndex = INDEX_NONE;
}

bool UMHDialogueSubsystem::IsConversationActive() const
{
    return ActiveConversationId != NAME_None && ActiveLineIndex != INDEX_NONE;
}

bool UMHDialogueSubsystem::GetActiveConversation(FMHDialogueConversation& OutConversation) const
{
    return FindConversation(ActiveConversationId, OutConversation);
}

bool UMHDialogueSubsystem::GetCurrentLine(FText& OutLineText, FName& OutSpeaker) const
{
    FMHDialogueConversation Conversation;
    if (!GetActiveConversation(Conversation) || !Conversation.Lines.IsValidIndex(ActiveLineIndex))
    {
        return false;
    }

    OutLineText = FText::FromString(Conversation.Lines[ActiveLineIndex].Text);
    OutSpeaker = FName(*Conversation.Speaker);
    return true;
}

bool UMHDialogueSubsystem::FindConversation(FName ConversationId, FMHDialogueConversation& OutConversation) const
{
    for (const FMHDialogueConversation& Conversation : Conversations)
    {
        if (Conversation.ConversationId == ConversationId)
        {
            OutConversation = Conversation;
            return true;
        }
    }

    return false;
}

bool UMHDialogueSubsystem::ApplyCompletion(const FMHDialogueCompletion& Completion, bool bPlayerInVehicle)
{
    if (!Completion.bCompleteObjective)
    {
        return false;
    }

    if (Completion.bRequireOnFoot && bPlayerInVehicle)
    {
        UE_LOG(LogTemp, Warning, TEXT("MountHope: dialogue objective requires on-foot."));
        return false;
    }

    UWorld* World = GetWorld();
    if (!World)
    {
        return false;
    }

    if (AMHGameModeBase* GameMode = Cast<AMHGameModeBase>(World->GetAuthGameMode()))
    {
        return GameMode->CompleteCurrentObjective(bPlayerInVehicle);
    }

    return false;
}

void UMHDialogueSubsystem::BroadcastCurrentLine()
{
    FText LineText;
    FName Speaker;
    if (!GetCurrentLine(LineText, Speaker))
    {
        return;
    }

    OnDialogueLineChanged.Broadcast(ActiveConversationId, Speaker, LineText);

    UE_LOG(LogTemp, Log, TEXT("MountHope Dialogue [%s]: %s"), *Speaker.ToString(), *LineText.ToString());
}
