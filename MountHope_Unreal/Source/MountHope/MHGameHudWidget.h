#pragma once

#include "CoreMinimal.h"
#include "Blueprint/UserWidget.h"
#include "MHGameHudWidget.generated.h"

class UTextBlock;
class UVerticalBox;
class UOverlay;
class UImage;
class AMHMinimapCaptureActor;

UCLASS()
class MOUNTHOPE_API UMHGameHudWidget : public UUserWidget
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void SetDialogueLine(const FText& Speaker, const FText& Line);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void ClearDialogue();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void SetObjectiveText(const FText& Objective);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void SetStatusText(const FText& Status);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void SetWantedText(const FText& Wanted);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void SetRadioText(const FText& Radio);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|HUD")
    void RefreshHud();

protected:
    virtual void NativeConstruct() override;
    virtual void NativeDestruct() override;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UOverlay> RootOverlay;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> ObjectiveTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> StatusTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> WantedTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> RadioTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> SpeakerTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> DialogueLineTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UVerticalBox> DialogueBox;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UTextBlock> ToastTextBlock;

    UPROPERTY(meta = (BindWidgetOptional))
    TObjectPtr<UImage> MinimapImage;

private:
    void EnsureWidgetTreeBuilt();
    void RefreshMinimap();
    void BindSubsystemDelegates();
    void UnbindSubsystemDelegates();
    void RefreshObjectiveAndStatus();

    UFUNCTION()
    void HandleDialogueLineChanged(FName ConversationId, FName Speaker, FText LineText);

    UFUNCTION()
    void HandleDialogueEnded(FName ConversationId);

    UFUNCTION()
    void HandleStationChanged(FName StationId);

    UFUNCTION()
    void HandleSongChanged(FName StationId, FString SongTitle);

    UFUNCTION()
    void HandleMissionCompleted(FString Title, FString CompletionMessage);

    UFUNCTION()
    void HandleCollectibleFound(FName ItemId, int32 CollectedCount, int32 TotalCount);

    void SetTextBlockContent(UTextBlock* TextBlock, const FText& Content, bool bCollapseWhenEmpty);
    void ClearToast();

    bool bDelegatesBound = false;
    FTimerHandle ToastTimerHandle;

    UPROPERTY(Transient)
    TObjectPtr<AMHMinimapCaptureActor> CachedMinimapCapture;
};
