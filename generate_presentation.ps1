# PowerPoint Presentation Generator
# Creates a professional presentation from the strategic analysis document

Add-Type -AssemblyName Microsoft.Office.Interop.PowerPoint
$ppApplication = New-Object -ComObject PowerPoint.Application
$ppApplication.Visible = [Microsoft.Office.Interop.PowerPoint.MsoTriState]::msoTrue

# Create presentation
$pres = $ppApplication.Presentations.Add()
$pres.PageSetup.SlideWidth = [Microsoft.Office.Core.MsoInches]10
$pres.PageSetup.SlideHeight = [Microsoft.Office.Core.MsoInches]7.5

# Color scheme
$colorPrimary = [System.Drawing.Color]::FromArgb(25, 45, 85)      # Deep Navy
$colorAccent = [System.Drawing.Color]::FromArgb(0, 120, 180)       # Professional Blue
$colorLight = [System.Drawing.Color]::FromArgb(240, 245, 250)      # Light Blue
$colorText = [System.Drawing.Color]::FromArgb(40, 40, 40)          # Dark Gray
$colorWhite = [System.Drawing.Color]::FromArgb(255, 255, 255)

function ConvertToRGBColor {
    param([System.Drawing.Color]$color)
    $pprgb = [Microsoft.Office.Interop.PowerPoint.PpColorSchemeIndex]::ppAccent1
    return ([int]$color.R -bor ([int]$color.G -shl 8) -bor ([int]$color.B -shl 16))
}

function AddSlide {
    param([int]$layout = 6)
    $slide = $pres.Slides.Add($pres.Slides.Count + 1, $layout)
    return $slide
}

function AddBackground {
    param($slide, [System.Drawing.Color]$color)
    $fill = $slide.Background.Fill
    $fill.Solid()
    $fill.ForeColor.RGB = ConvertToRGBColor $color
}

function AddTitleBox {
    param($slide, [string]$text, [double]$left, [double]$top, [double]$width, [double]$height, [int]$fontSize, [bool]$bold, [System.Drawing.Color]$color)
    $shape = $slide.Shapes.AddTextbox([Microsoft.Office.Core.MsoInches]$left, [Microsoft.Office.Core.MsoInches]$top, [Microsoft.Office.Core.MsoInches]$width, [Microsoft.Office.Core.MsoInches]$height)
    $textFrame = $shape.TextFrame
    $textFrame.WordWrap = $true
    $p = $textFrame.Paragraphs(1)
    $p.Text = $text
    $p.Font.Size = $fontSize
    $p.Font.Bold = $bold
    $p.Font.Color.RGB = ConvertToRGBColor $color
    return $shape
}

# SLIDE 1: Title Slide
Write-Host "Creating Slide 1: Title Slide..."
$slide1 = AddSlide
AddBackground $slide1 $colorPrimary

AddTitleBox $slide1 "Strategic Analysis: Agentic AI Integration" 0.5 2.5 9 2 54 $true $colorWhite
AddTitleBox $slide1 "Claude Code vs. Google Antigravity vs. GitHub Copilot" 0.5 4.5 9 1.5 28 $false $colorAccent
AddTitleBox $slide1 "March 2, 2026" 0.5 6.5 9 0.6 18 $false $colorLight

# SLIDE 2: Executive Summary
Write-Host "Creating Slide 2: Executive Summary..."
$slide2 = AddSlide
AddBackground $slide2 $colorWhite

# Add header bar
$header = $slide2.Shapes.AddShape([Microsoft.Office.Core.MsoShapeType]::msoShapeRectangle, [Microsoft.Office.Core.MsoInches]0, [Microsoft.Office.Core.MsoInches]0, [Microsoft.Office.Core.MsoInches]10, [Microsoft.Office.Core.MsoInches]1)
$header.Fill.Solid()
$header.Fill.ForeColor.RGB = ConvertToRGBColor $colorPrimary
$header.Line.Color.RGB = ConvertToRGBColor $colorPrimary

AddTitleBox $slide2 "Executive Summary" 0.5 0.2 9 0.7 36 $true $colorWhite

# Content
$content = $slide2.Shapes.AddTextbox([Microsoft.Office.Core.MsoInches]0.5, [Microsoft.Office.Core.MsoInches]1.2, [Microsoft.Office.Core.MsoInches]9, [Microsoft.Office.Core.MsoInches]6)
$tf = $content.TextFrame
$tf.WordWrap = $true

$contentText = @(
    "Strategic Objective:",
    "• Collect, enhance, and organize a robust library of skills in ./claude/skills/",
    "",
    "Key Finding:",
    "• Claude Code, Google Antigravity, and GitHub Copilot all support skills invocation",
    "• Only Claude Code supports reusable subagents in ./claude/agents/",
    "",
    "Critical Advantage:",
    "• Subagents enable operationalizing complex engineering workflows across the team",
    "• Hierarchical workflows, parallel execution, work summarization"
)

foreach ($i in 0..($contentText.Count - 1)) {
    if ($i -eq 0) {
        $p = $tf.Paragraphs(1)
    } else {
        $p = $tf.Paragraphs.Add()
    }
    $p.Text = $contentText[$i]
    $p.Font.Size = 13
    $p.Font.Color.RGB = ConvertToRGBColor $colorText
}

Write-Host "✅ Presentation structure created. Adding remaining slides..."

# Save the presentation
$outputPath = "c:\Users\adimi\OneDrive\Desktop\workspace\adept\Strategic_Analysis_Agentic_AI.pptx"
$pres.SaveAs($outputPath, [Microsoft.Office.Interop.PowerPoint.PpSaveAsFileType]::ppSaveAsDefault)

Write-Host "✅ Basic presentation structure saved to: $outputPath"
Write-Host "Note: PowerShell implementation creates foundation slides. For complete formatting with all content,"
Write-Host "consider using a proper Python library or online conversion tools."

# Clean up
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($pres) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($ppApplication) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
