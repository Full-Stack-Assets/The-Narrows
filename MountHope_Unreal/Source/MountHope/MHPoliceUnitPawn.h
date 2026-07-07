#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "MHPoliceUnitPawn.generated.h"

class UStaticMeshComponent;
class USoundBase;
class UAudioComponent;

UENUM(BlueprintType)
enum class EMHPoliceState : uint8
{
    // Close the distance to the player on foot.
    Pursue,
    // Hold position within weapon range and fire (armed units only).
    Attack
};

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHPoliceUnitPawn : public APawn
{
    GENERATED_BODY()

public:
    AMHPoliceUnitPawn();

    virtual void Tick(float DeltaSeconds) override;

    // Take damage (e.g. from the player's pistol). Death is observed via IsDead()
    // and handled by the pawn's own Tick / the spawner cleanup.
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ApplyDamage(float DamageAmount);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    bool IsDead() const { return Health <= 0.0f; }

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Police")
    EMHPoliceState GetState() const { return State; }

    // Configure this unit for a wanted-level tier when it is spawned.
    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Police")
    void ConfigureForTier(float InMaxHealth, bool bInArmed);

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    TObjectPtr<UStaticMeshComponent> BodyMesh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float ChaseSpeed = 1400.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float CatchRadius = 350.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float CatchDamage = 8.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float RepeatCatchCooldownSeconds = 2.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float MaxHealth = 40.0f;

    // Ranged combat (armed units only; enabled per wanted tier).
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    bool bArmed = false;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float AttackRange = 900.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float FireIntervalSeconds = 1.2f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Police")
    float ShotDamage = 6.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> SirenSound;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> GunshotSound;

private:
    void TryCatchPlayer(APawn* PlayerPawn);
    void TryShootPlayer(APawn* PlayerPawn, float DistanceSquared);
    bool HasLineOfSightTo(const APawn* PlayerPawn) const;

    UPROPERTY(Transient)
    TObjectPtr<UAudioComponent> SirenAudioComponent;

    EMHPoliceState State = EMHPoliceState::Pursue;
    float Health = 40.0f;
    float TimeSinceLastCatch = 999.0f;
    float TimeSinceLastShot = 999.0f;
};
