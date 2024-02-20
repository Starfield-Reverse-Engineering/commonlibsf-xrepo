package("commonlibsf")
    set_homepage("https://github.com/Starfield-Reverse-Engineering/CommonLibSF")
    set_description("A collaborative reverse-engineered library for Starfield")
    set_license("GPL-3.0")

    add_urls("https://github.com/Starfield-Reverse-Engineering/CommonLibSF.git")

    add_configs("sfse_xbyak", {description = "Enable trampoline support for Xbyak", default = false, type = "boolean"})

    add_deps("spdlog", { configs = { header_only = false, std_format = true } })

    add_syslinks("advapi32", "dbghelp", "ole32", "shell32", "user32", "version", "ws2_32")

    on_load("windows|x64", function(package)
        if package:config("sfse_xbyak") then
            package:add("defines", "SFSE_SUPPORT_XBYAK=1")
            package:add("deps", "xbyak")
        end
    end)

    on_install("windows|x64", function(package)
        import("package.tools.xmake").install(package, {
            sfse_xbyak = package:config("sfse_xbyak")
        }, { target = "commonlibsf" })
    end)

    on_test("windows|x64", function(package)
        assert(package:check_cxxsnippets({test = [[
            SFSEPluginLoad(const SFSE::LoadInterface*) {
                return true;
            };
        ]]}, { configs = { languages = "c++23" }, includes = "SFSE/SFSE.h" }))
    end)
