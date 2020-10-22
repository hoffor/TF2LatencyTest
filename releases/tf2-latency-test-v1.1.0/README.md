# TF2 Latency Test

Compatible with Windows 7 and 10

TF2 Latency Test is an AutoHotkey script + TF2 map that tests for and generates a report containing 'input-to-frame' latency values for Team Fortress 2, accurate to 1ms.

This script was made with [Team Comtress 2](https://github.com/mastercomfig/team-comtress-2) in mind and should work in both TF2/TC2.

This script measures latency from the moment the software mouse position changes to the moment a pixel in the GPU screen buffer is updated as a response to that movement. The script uses mouselook rather than button press because it's what the player is most sensitive to.

At the end of each test, you're encouraged to [Submit a result](https://docs.google.com/forms/d/e/1FAIpQLSenFVEHYT3jpUcolGElqH0bZ4LISdqP2JtA8cM-ynkH1zmdmQ/viewform)

[Manually approved responses](https://docs.google.com/spreadsheets/d/1jtfsMihu-aC4KHmbuyKqc5AhQmlL2ty1w1bELrx1GlY)

[All responses (unmoderated)](https://docs.google.com/spreadsheets/d/1U6YvW_m_LNdO31g9nDXu9pjNXjrtkaW0H78t6AGIIE8)

---

### IMPORTANT:

The script requires the game to be in borderless windowed mode or alternatively Win10's 'fullscreen optimizations' mode in order to grab pixel color data, and only Windows 7 or Vista allow desktop composition to be disabled. This means on Windows 10 or 8.X, results can be up to 40% (avg ~28%) higher than the values you'd get in Windows 7. Regardless of how bad that sounds, they should still be good ballpark estimates of your game's performance, since they're relatively small values to begin with.

With desktop composition enabled, Windows effectively limits your GPU to your monitor's refresh rate. In addition the script's functions themselves perform 1600-3200x slower.

In Win7, the script's performance is less consistent with visual styles and other GUI enhancements enabled. Script performance aside, in fullscreen, the difference between Win10 and Win7 TF2 performance seems to be unmeasurable, so that's nice.


---

## Instructions to disable desktop composition and GUI enhancements:

1. On Windows 7, search in start menu "performance options" and click the item with the same name

2. Under the "Visual effects" tab, click "Adjust for best performance" and wait for Windows 98 to kick in

When you're done testing, set this back how you like it, and consider right clicking your desktop -> Personalize, and set your theme back to the way you like it.


---


## Instructions for running script in-game:

NOTE: I'd recommend you run the script once with your typical TF2/system configuration (+disable desktop composition), and then once with all noisy background processes closed and with Windows' High Performance power plan enabled.

1. From the latest .zip file obtained from Releases, place the latency-test folder inside .."\Steam\steamapps\Team Fortress 2\tf\custom\". The script .exe or .ahk can go anywhere.

2. Set up your preferred TF2 or TC2 settings and configuration for testing. DO NOT use custom HUD crosshairs if they cover the exact center pixel of the game window.

3. Start TF2 or TC2 with launch options: `-noborder -insecure`
    - Last I knew, Mastercomfig recommended against using `-window` / `-sw` / `-windowed` for potential video mode issues.
    - This script is VAC safe, but if you're still worried then hopefully `-insecure` might ease your mind (disallows connecting to VAC servers).

4. Through the game options (not console), apply both your desired resolution and windowed mode. If using Win10, you may use fullscreen AS LONG AS 'fullscreen optimizations' is enabled, otherwise script will not work at all. Windowed mode is the simpler choice and performance between the two will be identical afaik.

5. Run the script and follow the instructions in the message box.

---

### AutoHotkey info:

The script .exe is just the .ahk script's contents packaged with AHK runtimes using ahk2exe, so there's no need to install AutoHotkey unless you're modifying it. The script .exe shows AHK version in the "Details" tab under "Product version" (not "File version") in Windows file properties.

[AutoHotkey](https://www.autohotkey.com/) (any "Current version" will work, not v1.0 or v2) & [Source code](https://github.com/Lexikos/AutoHotkey_L)
