#include "MHOpenWorldSubsystem.h"

FMHMapSourceProfile UMHOpenWorldSubsystem::GetDefaultMapSource() const
{
    FMHMapSourceProfile Profile;
    Profile.Name = TEXT("SouthCoastOSM");
    // Kept in sync with UMHGameInstance::SlicePath, the actual path UMHWorldSliceSubsystem loads
    // at runtime — this profile is metadata for future multi-region (Brockton/Cape Cod) sources,
    // not an independent load path.
    Profile.SourcePath = TEXT("../QUAHOG_Web/public/slice-newbedford.json");
    Profile.MetersToUnrealUnits = 100.0f;
    Profile.bAllowFictionalizedEdits = true;
    return Profile;
}
