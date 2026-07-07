#include "MHMinimapCaptureActor.h"

#include "Components/SceneCaptureComponent2D.h"
#include "Engine/TextureRenderTarget2D.h"
#include "Kismet/GameplayStatics.h"

AMHMinimapCaptureActor::AMHMinimapCaptureActor()
{
    PrimaryActorTick.bCanEverTick = true;

    CaptureComponent = CreateDefaultSubobject<USceneCaptureComponent2D>(TEXT("CaptureComponent"));
    RootComponent = CaptureComponent;

    CaptureComponent->ProjectionType = ECameraProjectionMode::Orthographic;
    CaptureComponent->OrthoWidth = OrthoWidth;
    CaptureComponent->bCaptureEveryFrame = true;
    CaptureComponent->CaptureSource = ESceneCaptureSource::SCS_FinalColorLDR;
    CaptureComponent->SetRelativeRotation(FRotator(-90.0f, 0.0f, 0.0f));
}

void AMHMinimapCaptureActor::BeginPlay()
{
    Super::BeginPlay();
    CreateRenderTarget();
}

void AMHMinimapCaptureActor::CreateRenderTarget()
{
    RenderTarget = NewObject<UTextureRenderTarget2D>(this);
    RenderTarget->InitAutoFormat(RenderTargetSize, RenderTargetSize);
    RenderTarget->UpdateResourceImmediate(true);

    if (CaptureComponent)
    {
        CaptureComponent->TextureTarget = RenderTarget;
        CaptureComponent->OrthoWidth = OrthoWidth;
    }
}

void AMHMinimapCaptureActor::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    APawn* PlayerPawn = UGameplayStatics::GetPlayerPawn(GetWorld(), 0);
    if (!PlayerPawn)
    {
        return;
    }

    const FVector PlayerLocation = PlayerPawn->GetActorLocation();
    SetActorLocation(FVector(PlayerLocation.X, PlayerLocation.Y, PlayerLocation.Z + CaptureHeightAboveGround));

    // CaptureComponent's -90 pitch is set once in the constructor and never changes; only the
    // actor's yaw needs to update per tick to follow the player.
    const float Yaw = bFollowPlayerYaw ? PlayerPawn->GetActorRotation().Yaw : 0.0f;
    SetActorRotation(FRotator(0.0f, Yaw, 0.0f));
}
