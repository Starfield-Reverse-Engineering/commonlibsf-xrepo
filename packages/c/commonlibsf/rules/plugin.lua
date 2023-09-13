-- Usage:
--
-- add_rules("@commonlibsf/plugin", {
--     name = "Plugin Name",
--     author = "Author Name",
--     description = "Plugin Description",
--     email = "user@site.com"
-- })

local PLUGIN_FILE = [[
#include <SFSE/SFSE.h>
#include <REL/Relocation.h>

using namespace std::literals;

extern "C" __declspec(dllexport)
constinit auto SFSEPluginVersion = []() noexcept {
    REL::Version ver{ ${PLUGIN_VERSION_MAJOR}, ${PLUGIN_VERSION_MINOR}, ${PLUGIN_VERSION_PATCH} };
    SFSE::PluginVersionData v{};
    v.PluginVersion(ver.pack());
    v.PluginName("${PLUGIN_NAME}");
    v.AuthorName("${PLUGIN_AUTHOR}");
    v.UsesSigScanning(true);
    v.HasNoStructUse(true);
    v.CompatibleVersions({ SFSE::RUNTIME_LATEST });
    return v;
}();]]

local VERSION_FILE = [[
#include <winres.h>

1 VERSIONINFO
FILEVERSION ${PLUGIN_VERSION_MAJOR}, ${PLUGIN_VERSION_MINOR}, ${PLUGIN_VERSION_PATCH}, 0
PRODUCTVERSION ${PROJECT_VERSION_MAJOR}, ${PROJECT_VERSION_MINOR}, ${PROJECT_VERSION_PATCH}, 0
FILEFLAGSMASK 0x17L
#ifdef _DEBUG
    FILEFLAGS 0x1L
#else
    FILEFLAGS 0x0L
#endif
FILEOS 0x4L
FILETYPE 0x1L
FILESUBTYPE 0x0L
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904b0"
        BEGIN
            VALUE "FileDescription", "${PLUGIN_DESCRIPTION}"
            VALUE "FileVersion", "${PLUGIN_VERSION}.0"
            VALUE "InternalName", "${PLUGIN_NAME}"
            VALUE "LegalCopyright", "${PLUGIN_AUTHOR} | ${PLUGIN_LICENSE}"
            VALUE "ProductName", "${PROJECT_NAME}"
            VALUE "ProductVersion", "${PROJECT_VERSION}.0"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1200
    END
END]]

rule("plugin")
    add_deps("win.sdk.resource")

    on_config(function(target)
        import("core.base.semver")
        import("core.project.depend")
        import("core.project.project")

        target:set("arch", "x64")
        target:set("kind", "shared")

        local configs = target:extraconf("rules", "@commonlibsf/plugin")
        local config_dir = path.join(target:autogendir(), "rules", "commonlibsf", "plugin")

        if configs.options == nil then
            configs.options = {}
        end

        local config_map = {
            PLUGIN_AUTHOR         = configs.author or "",
            PLUGIN_DESCRIPTION    = configs.description or "",
            PLUGIN_EMAIL          = configs.email or "",
            PLUGIN_LICENSE        = (target:license() or "Unknown") .. " License",
            PLUGIN_NAME           = configs.name or target:name(),
            PLUGIN_VERSION        = target:version() or "0.0.0",
            PLUGIN_VERSION_MAJOR  = semver.new(target:version() or "0.0.0"):major(),
            PLUGIN_VERSION_MINOR  = semver.new(target:version() or "0.0.0"):minor(),
            PLUGIN_VERSION_PATCH  = semver.new(target:version() or "0.0.0"):patch(),
            PROJECT_NAME          = project.name() or "",
            PROJECT_VERSION       = project.version() or "0.0.0",
            PROJECT_VERSION_MAJOR = semver.new(project.version() or "0.0.0"):major(),
            PROJECT_VERSION_MINOR = semver.new(project.version() or "0.0.0"):minor(),
            PROJECT_VERSION_PATCH = semver.new(project.version() or "0.0.0"):patch(),
        }

        local config_parse = function(str)
            return str:gsub("(%${([^\n]-)})", function(_, var)
                local result = config_map[var:trim()]
                if type(result) ~= "string" then
                    result = tostring(result)
                end
                assert(result ~= nil, "cannot get variable(%s)", var)
                return result
            end)
        end

        local plugin_file = path.join(config_dir, "plugin.cpp")
        depend.on_changed(function()
            local file = io.open(plugin_file, "w")
            if file then
                file:write(config_parse(PLUGIN_FILE), "\n")
                file:close()
            end
        end, { dependfile = target:dependfile(plugin_file), files = project.allfiles()})

        local version_file = path.join(config_dir, "version.rc")
        depend.on_changed(function()
            local file = io.open(version_file, "w")
            if file then
                file:write(config_parse(VERSION_FILE), "\n")
                file:close()
            end
        end, { dependfile = target:dependfile(version_file), files = project.allfiles()})

        target:add("files", plugin_file)
        target:add("files", version_file)
    end)
