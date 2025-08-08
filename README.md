# ProfileSync

A World of Warcraft addon that synchronizes addon profiles across characters, with robust API versioning and compatibility checking.

## Features

- **Cross-character profile synchronization** for supported addons
- **API versioning and compatibility checking** to handle addon updates
- **Auto-apply profiles** for new characters
- **Comprehensive error handling** with detailed feedback
- **User-friendly interface** with compatibility indicators
- **Fallback methods** for API changes

## Supported Addons

ProfileSync currently supports the following addons with version compatibility:

### Details
- **Versions:** 3.0.0 - 4.0.0
- **API Methods:** `Details:GetProfileList()`, `Details:SetProfile()`
- **Fallback:** `Details.profile:GetProfileList()`, `Details.profile:SetProfile()`
- **Reload Required:** No

### Plater
- **Versions:** 1.0.0 - 2.0.0
- **API Methods:** `Plater:GetProfileList()`, `Plater:SwitchProfile()`
- **Fallback:** `Plater.db:GetProfileList()`, `Plater.db:SetProfile()`
- **Reload Required:** Yes

### Bartender4
- **Versions:** 4.0.0 - 5.0.0
- **API Methods:** `Bartender4.db:GetProfileList()`, `Bartender4.db:SetProfile()`
- **Fallback:** `Bartender4:GetProfileList()`, `Bartender4:SetProfile()`
- **Reload Required:** No

### Cell
- **Versions:** 1.0.0 - 2.0.0
- **API Methods:** Direct database access (`CellDB.profiles`, `CellDB["profile"]`)
- **Fallback:** `Cell:GetProfileList()`, `Cell:SetProfile()`
- **Reload Required:** Yes

## Installation

1. Download the addon files
2. Place them in your `World of Warcraft/_retail_/Interface/AddOns/ProfileSync/` directory
3. Restart World of Warcraft or reload the UI
4. Type `/profilesync` to open the interface

## Usage

### Basic Commands

- `/profilesync` or `/ps` - Open the main interface
- `/profilesync help` - Show available commands
- `/profilesync version` - Show addon version
- `/profilesync apply` - Apply all configured profiles
- `/profilesync reset` - Reset character data
- `/profilesync compatibility` - Show compatibility report
- `/profilesync status` - Show detailed status report

### Setting Up Profiles

1. Open the ProfileSync interface (`/profilesync`)
2. Enable "Auto-apply profiles on new characters" if desired
3. For each supported addon:
   - Select the profile you want to use from the dropdown
   - The interface shows version compatibility with ✓/✗ indicators
4. Click "Apply Profiles" to test your configuration

### Auto-Apply Feature

When enabled, ProfileSync will automatically apply saved profiles when you log into a new character for the first time. This is useful for maintaining consistent settings across all your characters.

## API Compatibility Matrix

The addon uses a sophisticated versioning system to handle API changes in supported addons:

### Version Detection

ProfileSync attempts to detect addon versions using multiple methods:
1. `GetAddOnMetadata(addonName, "Version")` - Standard WoW API
2. Addon-specific version variables (e.g., `Details.version`)
3. Fallback to "0.0.0" if no version is detected

### Compatibility Checking

For each supported addon, ProfileSync maintains:
- **Minimum Version:** Oldest supported version
- **Maximum Version:** Newest supported version
- **API Versions:** Specific API implementations for different version ranges

### Fallback Methods

When an addon's API changes between versions, ProfileSync includes fallback methods:
- Primary API methods for current versions
- Alternative API methods for newer versions
- Graceful degradation when APIs are unavailable

## Development

### Adding Support for New Addons

To add support for a new addon, update the `APICompatibility` table in `handlers.lua`:

```lua
PS.APICompatibility["NewAddon"] = {
    minVersion = "1.0.0",
    maxVersion = "2.0.0",
    apiVersions = {
        ["1.0.0"] = {
            getProfiles = function()
                -- Return list of available profiles
                return NewAddon:GetProfiles()
            end,
            setProfile = function(profileName)
                -- Apply the specified profile
                NewAddon:SetProfile(profileName)
                return true
            end
        },
        ["2.0.0"] = {
            getProfiles = function()
                -- Updated API for newer versions
                return NewAddon.db:GetProfiles()
            end,
            setProfile = function(profileName)
                -- Updated API for newer versions
                NewAddon.db:SetProfile(profileName)
                return true
            end
        }
    }
}
```

### Version Comparison

The addon uses semantic versioning comparison:
- Major.Minor.Patch format (e.g., "1.2.3")
- Handles missing version components gracefully
- Supports version ranges for compatibility

### Error Handling

ProfileSync provides comprehensive error handling:
- Version compatibility validation
- API availability checking
- Profile existence verification
- Detailed error messages for troubleshooting

## Troubleshooting

### Common Issues

1. **"Addon not supported"**
   - The addon isn't in the compatibility matrix
   - Check if the addon is supported or needs to be added

2. **"Version incompatibility"**
   - The addon version is outside the supported range
   - Update the addon or contact the developer to add support

3. **"API not available"**
   - The addon's API has changed
   - Check for addon updates or report the issue

4. **"Profile not found"**
   - The selected profile doesn't exist in the addon
   - Refresh the profile list or create the profile first

### Debug Information

Use `/profilesync status` to get detailed information about:
- Addon compatibility status
- Version information
- Saved profile configuration
- Auto-apply settings

## Contributing

When contributing to ProfileSync:

1. **Test thoroughly** with different addon versions
2. **Update the compatibility matrix** when adding new addons
3. **Include fallback methods** for API changes
4. **Document version requirements** clearly
5. **Test error conditions** and edge cases

## License

This addon is provided as-is for personal use. Please respect the licenses of supported addons when using this tool.

## Version History

### 1.0.0
- Initial release
- Support for Details, Plater, Bartender4, and Cell
- API versioning and compatibility checking
- Auto-apply functionality
- Comprehensive error handling