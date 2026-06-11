local ok_nui, _ = pcall(require, "nui.layout")
if not ok_nui then
    vim.notify("[NewProject] Requiere nui.nvim — instálalo primero.", vim.log.levels.ERROR)
    return {}
end

local Popup = require("nui.popup")
local Layout = require("nui.layout")
local event = require("nui.utils.autocmd").event

-- ─── Highlights ───────────────────────────────────────────────────────────────
local function setup_highlights()
    vim.cmd("highlight! link NpBg Normal")
    vim.cmd("highlight! link NpPanel NormalFloat")
    vim.cmd("highlight! link NpSel CursorLine")
    vim.cmd("highlight! link NpTitle FloatTitle")
    vim.cmd("highlight! link NpDim Comment")
    vim.cmd("highlight! link NpAccent Function")
    vim.cmd("highlight! link NpAccent2 Statement")
    vim.cmd("highlight! link NpBorder FloatBorder")
    vim.cmd("highlight! link NpGreen DiagnosticOk")
    vim.cmd("highlight! link NpRed DiagnosticError")
    vim.cmd("highlight! link NpGroup Comment")
    vim.cmd("highlight! link NpBtnOk DiffAdd")
    vim.cmd("highlight! link NpBtnCancel DiffDelete")
    vim.cmd("highlight! link NpCheck DiagnosticOk")
    vim.cmd("highlight! link NpBuildSel Visual")
    vim.cmd("highlight! link NpBuildNorm NormalFloat")
    local nf = vim.api.nvim_get_hl(0, { name = "NormalFloat" })
    vim.api.nvim_set_hl(0, "NpInput", {
        bg = nf.bg or 0x2a2d3e,
        fg = nf.fg,
        underline = false,
        undercurl = false,
        bold = false,
        italic = false,
    })
end

-- ─── Estado ───────────────────────────────────────────────────────────────────
local state = {
    project_type = "Java",
    name = "untitled",
    location = "~/Documents/CodigosProgramacion/",
    git = false,
    build_system = "IntelliJ",
    sample_code = true,
    advanced = false,
    list_cursor = 1,
}

local PROJECT_TYPES = {
    { label = "Java", icon = "󰆦 ", group = "New Project" },
    { label = "Kotlin", icon = " ", group = "New Project" },
    { label = "Groovy", icon = " ", group = "New Project" },
    { label = "Empty Project", icon = " ", group = "New Project" },
    { label = "Maven Archetype", icon = " ", group = "Generators" },
    { label = "JavaFX", icon = "  ", group = "Generators" },
    { label = "Spring", icon = " ", group = "Generators" },
}

local BUILD_SYSTEMS = { "IntelliJ", "Maven", "Gradle" }
local LABEL_W = 12

local ROWS = {
    NAME     = 1,
    LOCATION = 4,
    GIT      = 8,
    BUILD    = 10,
    JDK      = 12,
    SAMPLE   = 14,
    ADVANCED = 16,
    BTN      = 22,
}

local INTERACTIVE = {
    ROWS.NAME, ROWS.LOCATION, ROWS.GIT, ROWS.BUILD,
    ROWS.JDK, ROWS.SAMPLE, ROWS.ADVANCED, ROWS.BTN,
}

local INPUT_ROW = { ROWS.NAME, ROWS.LOCATION, ROWS.JDK }

-- ─── Helper escritura de archivos ─────────────────────────────────────────────
local function write_file(path, content)
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
    end
end

-- ─── Panel izquierdo ──────────────────────────────────────────────────────────
local function render_left(bufnr)
    vim.bo[bufnr].modifiable = true
    local lines, hls = {}, {}

    local function push(text, hg, indent)
        indent = indent or 0
        local row = #lines
        table.insert(lines, string.rep(" ", indent) .. text)
        if hg then
            table.insert(hls, { row, indent, -1, hg })
        end
    end

    push("", nil)
    local last_group = nil
    for i, pt in ipairs(PROJECT_TYPES) do
        if pt.group ~= last_group then
            if last_group ~= nil then push("", nil) end
            push(pt.group, "NpGroup", 1)
            last_group = pt.group
        end
        push(pt.icon .. " " .. pt.label, "NpPanel", 2)
    end
    push("", nil)
    push("  More via plugins…", "NpAccent", 0)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
    local ns = vim.api.nvim_create_namespace("np_left")
    for _, h in ipairs(hls) do
        vim.api.nvim_buf_add_highlight(bufnr, ns, h[4], h[1], h[2], h[3])
    end
    vim.bo[bufnr].modifiable = false

    local lwin = vim.fn.bufwinid(bufnr)
    if lwin ~= -1 then
        local line = 2
        local last_grp = nil
        for i, pt in ipairs(PROJECT_TYPES) do
            if pt.group ~= last_grp then
                if last_grp ~= nil then line = line + 1 end
                line = line + 1
                last_grp = pt.group
            end
            if i == state.list_cursor then break end
            line = line + 1
        end
        pcall(vim.api.nvim_win_set_cursor, lwin, { line, 2 })
    end
end

-- ─── Panel derecho ────────────────────────────────────────────────────────────
local function render_right(bufnr)
    vim.bo[bufnr].modifiable = true
    local ns = vim.api.nvim_create_namespace("np_right")
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    local lines, hls = {}, {}
    local function push(text, hg, indent)
        indent = indent or 0
        local row = #lines
        table.insert(lines, string.rep(" ", indent) .. text)
        if hg then table.insert(hls, { row, indent, -1, hg }) end
    end
    local function blank() table.insert(lines, "") end

    blank()
    push("Name:     ", "NpDim", 2)
    blank()
    blank()
    push("Location: ", "NpDim", 2)
    blank()
    push("  Project will be created in: " .. state.location .. "/" .. state.name, "NpDim", 0)
    blank()
    local git_box = state.git and "[✓] Create Git repository" or "[ ] Create Git repository"
    push(git_box, state.git and "NpCheck" or "NpDim", 2)
    blank()
    local bs_line = "Build System:    "
    for _, bs in ipairs(BUILD_SYSTEMS) do
        bs_line = bs_line .. (bs == state.build_system and ("[ " .. bs .. " ]  ") or ("  " .. bs .. "   "))
    end
    push(bs_line, "NpBg", 2)
    blank()
    push("JDK:      ", "NpDim", 2)
    blank()
    local sc_box = state.sample_code and "[✓] Add sample code" or "[ ] Add sample code"
    push(sc_box, state.sample_code and "NpCheck" or "NpDim", 2)
    blank()
    local adv_icon = state.advanced and "▼" or "▶"
    push(adv_icon .. " Advanced Settings", "NpDim", 2)
    blank()
    blank()
    blank()
    push("─────────────────────────────────────────────────────", "NpBorder", 2)
    push("  ╭────────────╮  ╭────────────╮ ", "NpBg", 2)
    push("  │   CREATE   │  │   CANCEL   │ ", "NpBg", 2)
    push("  ╰────────────╯  ╰────────────╯ ", "NpBg", 2)

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    for _, h in ipairs(hls) do
        vim.api.nvim_buf_add_highlight(bufnr, ns, h[4], h[1], h[2], h[3])
    end

    local col = 2 + #"Build System:    "
    for _, bs in ipairs(BUILD_SYSTEMS) do
        local btn = (bs == state.build_system) and ("[ " .. bs .. " ]") or ("  " .. bs .. "  ")
        local hg = (bs == state.build_system) and "NpBuildSel" or "NpBuildNorm"
        vim.api.nvim_buf_add_highlight(bufnr, ns, hg, 10, col, col + #btn)
        col = col + #btn + 2
    end

    for row = 21, 23 do
        vim.api.nvim_buf_add_highlight(bufnr, ns, "NpBtnOk", row, 2, 16)
        vim.api.nvim_buf_add_highlight(bufnr, ns, "NpBtnCancel", row, 18, 32)
    end

    vim.bo[bufnr].modifiable = false
end

-- ─── Input flotante ───────────────────────────────────────────────────────────
local function make_inline_input(rwin, row_inside, placeholder)
    local pos = vim.api.nvim_win_get_position(rwin)
    local rw = vim.api.nvim_win_get_width(rwin)
    local abs_row = pos[1] + row_inside
    local abs_col = pos[2] + 1 + 2 + LABEL_W
    local inp_w = rw - 2 - LABEL_W - 3

    local p = Popup({
        relative = "editor",
        position = { row = abs_row, col = abs_col },
        size = { width = inp_w, height = 1 },
        focusable = true,
        border = { style = "rounded" },
        win_options = { winhighlight = "Normal:NpInput,FloatBorder:NpBorder" },
        zindex = 60,
    })
    p:mount()
    vim.api.nvim_buf_set_lines(p.bufnr, 0, -1, false, { placeholder })
    return p
end

-- ─── Creación de proyectos ────────────────────────────────────────────────────
local function create_intellij_project(full_path)
    local name = state.name

    vim.fn.mkdir(full_path .. "/src", "p")
    vim.fn.mkdir(full_path .. "/out/production/" .. name, "p")
    vim.fn.mkdir(full_path .. "/.idea", "p")

    write_file(full_path .. "/.idea/misc.xml", table.concat({
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<project version="4">',
        '  <component name="ProjectRootManager" version="2" languageLevel="JDK_21" default="true" project-jdk-name="21" project-jdk-type="JavaSDK">',
        '    <output url="file://$PROJECT_DIR$/out" />',
        '  </component>',
        '</project>',
        '',
    }, "\n"))

    write_file(full_path .. "/.idea/modules.xml", table.concat({
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<project version="4">',
        '  <component name="ProjectModuleManager">',
        '    <modules>',
        '      <module fileurl="file://$PROJECT_DIR$/' .. name .. '.iml" filepath="$PROJECT_DIR$/' .. name .. '.iml" />',
        '    </modules>',
        '  </component>',
        '</project>',
        '',
    }, "\n"))

    write_file(full_path .. "/.idea/workspace.xml", table.concat({
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<project version="4">',
        '  <component name="ProjectViewState">',
        '    <option name="hideEmptyMiddlePackages" value="true" />',
        '    <option name="showLibraryContents" value="true" />',
        '  </component>',
        '  <component name="PropertiesComponent">',
        '    <property name="RunOnceActivity.ShowReadmeOnStart" value="true" />',
        '  </component>',
        '</project>',
        '',
    }, "\n"))

    write_file(full_path .. "/.idea/.gitignore", table.concat({
        "# Default ignored files",
        "/shelf/",
        "/workspace.xml",
        "# Editor-based HTTP Client requests",
        "/httpRequests/",
        "# Datasource local storage ignored files",
        "/dataSources/",
        "/dataSources.local.xml",
        "",
    }, "\n"))

    write_file(full_path .. "/" .. name .. ".iml", table.concat({
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<module type="JAVA_MODULE" version="4">',
        '  <component name="NewModuleRootManager" inherit-compiler-output="true">',
        '    <exclude-output />',
        '    <content url="file://$MODULE_DIR$">',
        '      <sourceFolder url="file://$MODULE_DIR$/src" isTestSource="false" />',
        '    </content>',
        '    <orderEntry type="inheritedJdk" />',
        '    <orderEntry type="sourceFolder" forTests="false" />',
        '  </component>',
        '</module>',
        '',
    }, "\n"))

    write_file(full_path .. "/.gitignore", table.concat({
        "# IntelliJ",
        ".idea/",
        "*.iml",
        "",
        "# Compiled",
        "out/",
        "*.class",
        "",
    }, "\n"))

    if state.sample_code then
        write_file(full_path .. "/src/Main.java", table.concat({
            "public class Main {",
            "    public static void main(String[] args) {",
            '        System.out.println("Hello, ' .. name .. '!");',
            "    }",
            "}",
            "",
        }, "\n"))
    end
end

local function create_maven_project(full_path)
    local src_main = full_path .. "/src/main/java/com/example"
    local src_test = full_path .. "/src/test/java/com/example"
    vim.fn.mkdir(src_main, "p")
    vim.fn.mkdir(src_test, "p")

    write_file(full_path .. "/pom.xml", table.concat({
        '<?xml version="1.0" encoding="UTF-8"?>',
        '<project xmlns="http://maven.apache.org/POM/4.0.0"',
        '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"',
        '         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">',
        "    <modelVersion>4.0.0</modelVersion>",
        "    <groupId>com.example</groupId>",
        "    <artifactId>" .. state.name .. "</artifactId>",
        "    <version>1.0-SNAPSHOT</version>",
        "    <properties>",
        "        <maven.compiler.source>21</maven.compiler.source>",
        "        <maven.compiler.target>21</maven.compiler.target>",
        "        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>",
        "    </properties>",
        "    <dependencies>",
        "        <dependency>",
        "            <groupId>junit</groupId>",
        "            <artifactId>junit</artifactId>",
        "            <version>4.13.2</version>",
        "            <scope>test</scope>",
        "        </dependency>",
        "    </dependencies>",
        "</project>",
        "",
    }, "\n"))

    write_file(full_path .. "/.gitignore", table.concat({
        "# Maven",
        "target/",
        "pom.xml.tag",
        "pom.xml.releaseBackup",
        "pom.xml.versionsBackup",
        "",
        "# IntelliJ",
        ".idea/",
        "*.iml",
        "",
        "# Compiled",
        "*.class",
        "",
    }, "\n"))

    if state.sample_code then
        write_file(src_main .. "/Main.java", table.concat({
            "package com.example;",
            "",
            "public class Main {",
            "    public static void main(String[] args) {",
            '        System.out.println("Hello, ' .. state.name .. '!");',
            "    }",
            "}",
            "",
        }, "\n"))

        write_file(src_test .. "/MainTest.java", table.concat({
            "package com.example;",
            "",
            "import org.junit.Test;",
            "import static org.junit.Assert.*;",
            "",
            "public class MainTest {",
            "    @Test",
            "    public void testMain() {",
            "        assertTrue(true);",
            "    }",
            "}",
            "",
        }, "\n"))
    end
end

local function create_gradle_project(full_path)
    local src_main = full_path .. "/src/main/java/com/example"
    local src_test = full_path .. "/src/test/java/com/example"
    vim.fn.mkdir(src_main, "p")
    vim.fn.mkdir(src_test, "p")

    write_file(full_path .. "/settings.gradle", table.concat({
        'rootProject.name = "' .. state.name .. '"',
        "",
    }, "\n"))

    write_file(full_path .. "/build.gradle", table.concat({
        "plugins {",
        "    id 'java'",
        "}",
        "",
        "group = 'com.example'",
        "version = '1.0-SNAPSHOT'",
        "",
        "repositories {",
        "    mavenCentral()",
        "}",
        "",
        "dependencies {",
        "    testImplementation 'junit:junit:4.13.2'",
        "}",
        "",
        "java {",
        "    sourceCompatibility = JavaVersion.VERSION_21",
        "    targetCompatibility = JavaVersion.VERSION_21",
        "}",
        "",
    }, "\n"))

    write_file(full_path .. "/.gitignore", table.concat({
        "# Gradle",
        ".gradle/",
        "build/",
        "",
        "# IntelliJ",
        ".idea/",
        "*.iml",
        "",
        "# Compiled",
        "*.class",
        "",
    }, "\n"))

    if state.sample_code then
        write_file(src_main .. "/Main.java", table.concat({
            "package com.example;",
            "",
            "public class Main {",
            "    public static void main(String[] args) {",
            '        System.out.println("Hello, ' .. state.name .. '!");',
            "    }",
            "}",
            "",
        }, "\n"))

        write_file(src_test .. "/MainTest.java", table.concat({
            "package com.example;",
            "",
            "import org.junit.Test;",
            "import static org.junit.Assert.*;",
            "",
            "public class MainTest {",
            "    @Test",
            "    public void testMain() {",
            "        assertTrue(true);",
            "    }",
            "}",
            "",
        }, "\n"))
    end
end

-- ─── Función principal ────────────────────────────────────────────────────────
local function open_new_project()
    setup_highlights()

    local left_popup = Popup({
        enter = true,
        focusable = true,
        border = {
            style = { "╭", "─", "┬", "│", "┤", "─", "╰", "│" },
            text = { top = " 🧩 New Project ", top_align = "center" },
        },
        buf_options = { modifiable = false },
        win_options = {
            winblend = 0,
            cursorline = true,
            winhighlight = "Normal:NpPanel,CursorLine:NpSel,FloatBorder:NpBorder",
        },
    })

    local right_popup = Popup({
        enter = false,
        focusable = true,
        border = { style = { "┬", "─", "╮", "│", "╯", "─", "┴", "│" } },
        buf_options = { modifiable = false },
        win_options = {
            winblend = 0,
            winhighlight = "Normal:NpBg,FloatBorder:NpBorder",
            cursorline = true,
        },
    })

    local layout = Layout(
        { position = "50%", size = { width = "75%", height = "90%" } },
        Layout.Box({
            Layout.Box(left_popup, { size = "30%" }),
            Layout.Box(right_popup, { size = "70%" }),
        }, { dir = "row" })
    )

    layout:mount()
    render_left(left_popup.bufnr)
    render_right(right_popup.bufnr)

    local rwin = right_popup.winid
    local lbuf = left_popup.bufnr
    local rbuf = right_popup.bufnr

    local input_name     = make_inline_input(rwin, ROWS.NAME,     state.name)
    local input_location = make_inline_input(rwin, ROWS.LOCATION, state.location)
    local input_jdk      = make_inline_input(rwin, ROWS.JDK,      " 21 Oracle OpenJDK 21.0.6")

    local function sync_state()
        state.name     = vim.api.nvim_buf_get_lines(input_name.bufnr, 0, 1, false)[1] or state.name
        state.location = vim.api.nvim_buf_get_lines(input_location.bufnr, 0, 1, false)[1] or state.location
        render_right(rbuf)
    end

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = input_name.bufnr, callback = sync_state,
    })
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = input_location.bufnr, callback = sync_state,
    })

    local function close_all()
        pcall(function() input_name:unmount() end)
        pcall(function() input_location:unmount() end)
        pcall(function() input_jdk:unmount() end)
        pcall(function() layout:unmount() end)
    end

    local function do_create()
        sync_state()
        close_all()
        local full_path = vim.fn.expand(state.location) .. "/" .. state.name
        vim.fn.mkdir(full_path, "p")

        if state.build_system == "Maven" then
            create_maven_project(full_path)
        elseif state.build_system == "Gradle" then
            create_gradle_project(full_path)
        else
            create_intellij_project(full_path)
        end

        if state.git then
            vim.fn.system("git -C " .. vim.fn.shellescape(full_path) .. " init")
        end

        vim.cmd("cd " .. vim.fn.fnameescape(full_path))
        vim.cmd("edit .")
        vim.notify(
            string.format(
                "✅ Proyecto '%s' creado en %s\n   Build: %s | Git: %s",
                state.name, full_path, state.build_system, state.git and "sí" or "no"
            ),
            vim.log.levels.INFO
        )
    end

    local bs_cursor = 1
    for i, bs in ipairs(BUILD_SYSTEMS) do
        if bs == state.build_system then bs_cursor = i end
    end
    local function cycle_build(dir)
        bs_cursor = ((bs_cursor - 1 + dir) % #BUILD_SYSTEMS) + 1
        state.build_system = BUILD_SYSTEMS[bs_cursor]
        render_right(rbuf)
    end

    local function set_right_cursor(row)
        vim.api.nvim_win_set_cursor(rwin, { row + 1, 0 })
    end
    local function get_right_row()
        return vim.api.nvim_win_get_cursor(rwin)[1] - 1
    end
    local function focus_right_at(row)
        vim.api.nvim_set_current_win(rwin)
        set_right_cursor(row)
    end

    local inputs = { input_name, input_location, input_jdk }
    local cur_inp = 1

    local function focus_input(idx)
        cur_inp = idx
        vim.api.nvim_set_current_win(inputs[idx].winid)
        vim.cmd("startinsert!")
    end

    local function next_inp()
        focus_input(cur_inp % #inputs + 1)
    end
    local function prev_inp()
        focus_input((cur_inp - 2) % #inputs + 1)
    end

    for i, inp in ipairs(inputs) do
        local idx = i
        local b = inp.bufnr
        local iopts = { buffer = b, noremap = true, silent = true }

        vim.keymap.set("i", "<Tab>",   next_inp,  iopts)
        vim.keymap.set("i", "<S-Tab>", prev_inp,  iopts)
        vim.keymap.set("n", "<Tab>",   next_inp,  iopts)
        vim.keymap.set("n", "<S-Tab>", prev_inp,  iopts)
        vim.keymap.set("n", "<CR>",    do_create, iopts)
        vim.keymap.set("n", "q",       close_all, iopts)

        vim.keymap.set("i", "<Esc>", function()
            vim.cmd("stopinsert")
            focus_right_at(INPUT_ROW[idx])
        end, iopts)
        vim.keymap.set("n", "<Esc>", function()
            focus_right_at(INPUT_ROW[idx])
        end, iopts)

        vim.keymap.set("n", "j", function()
            if idx < #inputs then
                focus_input(idx + 1)
            else
                local cur_row = INPUT_ROW[idx]
                for _, r in ipairs(INTERACTIVE) do
                    if r > cur_row then
                        focus_right_at(r)
                        return
                    end
                end
                focus_right_at(INTERACTIVE[#INTERACTIVE])
            end
        end, iopts)

        vim.keymap.set("n", "k", function()
            if idx > 1 then
                focus_input(idx - 1)
            else
                vim.api.nvim_set_current_win(left_popup.winid)
            end
        end, iopts)
    end

    local ropts = { noremap = true, silent = true, buffer = rbuf }

    vim.keymap.set("n", "j", function()
        local cur = get_right_row()
        for _, r in ipairs(INTERACTIVE) do
            if r > cur then set_right_cursor(r) return end
        end
        set_right_cursor(INTERACTIVE[#INTERACTIVE])
    end, ropts)

    vim.keymap.set("n", "k", function()
        local cur = get_right_row()
        for i = #INTERACTIVE, 1, -1 do
            if INTERACTIVE[i] < cur then set_right_cursor(INTERACTIVE[i]) return end
        end
        set_right_cursor(INTERACTIVE[1])
    end, ropts)

    local function activate_row()
        local row = get_right_row()
        local col = vim.api.nvim_win_get_cursor(rwin)[2]
        if row == ROWS.NAME then
            focus_input(1)
        elseif row == ROWS.LOCATION then
            focus_input(2)
        elseif row == ROWS.GIT then
            state.git = not state.git
            render_right(rbuf)
        elseif row == ROWS.BUILD then
            cycle_build(1)
        elseif row == ROWS.JDK then
            focus_input(3)
        elseif row == ROWS.SAMPLE then
            state.sample_code = not state.sample_code
            render_right(rbuf)
        elseif row == ROWS.ADVANCED then
            state.advanced = not state.advanced
            render_right(rbuf)
        elseif row == ROWS.BTN then
            if col < 16 then do_create() else close_all() end
        end
    end

    vim.keymap.set("n", "<CR>",    activate_row, ropts)
    vim.keymap.set("n", "<Space>", activate_row, ropts)

    vim.keymap.set("n", "h", function()
        if get_right_row() == ROWS.BUILD then cycle_build(-1) end
    end, ropts)
    vim.keymap.set("n", "l", function()
        if get_right_row() == ROWS.BUILD then cycle_build(1) end
    end, ropts)

    vim.keymap.set("n", "<Right>", function()
        if get_right_row() == ROWS.BTN then
            vim.api.nvim_win_set_cursor(rwin, { ROWS.BTN + 1, 20 })
        end
    end, ropts)
    vim.keymap.set("n", "<Left>", function()
        if get_right_row() == ROWS.BTN then
            vim.api.nvim_win_set_cursor(rwin, { ROWS.BTN + 1, 4 })
        end
    end, ropts)

    vim.keymap.set("n", "<Tab>", function() focus_input(1) end, ropts)
    vim.keymap.set("n", "q",     close_all, ropts)
    vim.keymap.set("n", "<Esc>", close_all, ropts)

    local lopts = { noremap = true, silent = true, buffer = lbuf }

    local function move_cursor(delta)
        state.list_cursor = math.max(1, math.min(#PROJECT_TYPES, state.list_cursor + delta))
        state.project_type = PROJECT_TYPES[state.list_cursor].label
        render_left(lbuf)
        render_right(rbuf)
    end

    vim.keymap.set("n", "j",      function() move_cursor(1)  end, lopts)
    vim.keymap.set("n", "k",      function() move_cursor(-1) end, lopts)
    vim.keymap.set("n", "<Down>", function() move_cursor(1)  end, lopts)
    vim.keymap.set("n", "<Up>",   function() move_cursor(-1) end, lopts)
    vim.keymap.set("n", "<Tab>",  function() focus_input(1)  end, lopts)
    vim.keymap.set("n", "<CR>",   function() focus_right_at(ROWS.NAME) end, lopts)
    vim.keymap.set("n", "q",      close_all, lopts)
    vim.keymap.set("n", "<Esc>",  close_all, lopts)

    layout:on(event.BufLeave, function() end)
    focus_input(1)
end

return { open = open_new_project }
