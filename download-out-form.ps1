[System.Reflection.Assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089") > $null

function out-form {
  param ($title = "", $data = $null, $columnNames = $null,
         $columnProperties = $null, $actions = $null)

  # a little data defaulting/validation
  if ($columnNames -eq $null) {
    $columnNames = $columnProperties
  }
  if ($columnProperties -eq $null -or
      $columnNames.Count -lt 1 -or
      $columnNames.Count -ne $columnProperties.Count) {
    throw "Data validation failed"
  }
  $numCols = $columnNames.Count

  # figure out form width
  $width = $numCols * 200
  $actionWidth = $actions.Count * 100 + 40
  if ($actionWidth -gt $width) {
    $width = $actionWidth
  }

  # set up form
  $form = new-object System.Windows.Forms.Form
  $form.text = $title
  $form.size = new-object System.Drawing.Size($width, 400)
  $panel = new-object System.Windows.Forms.Panel
  $panel.Dock = "Fill"
  $form.Controls.Add($panel)

  $lv = new-object windows.forms.ListView
  $panel.Controls.Add($lv)

  # add the buttons
  $btnPanel = new-object System.Windows.Forms.Panel
  $btnPanel.Height = 40
  $btnPanel.Dock = "Bottom"
  $panel.Controls.Add($btnPanel)

  $btns = new-object System.Collections.ArrayList
  if ($actions -ne $null) {
    $btnOffset = 20
    foreach ($action in $actions.GetEnumerator()) {
      $btn = new-object windows.forms.Button
      $btn.DialogResult = [System.Windows.Forms.DialogResult]"OK"
      $btn.Text = $action.name
      $btn.Left = $btnOffset
      $btn.Width = 80
      $btn.Top = 10
      $exprString = '{$lv.SelectedItems | foreach-object { $_.Tag } | foreach-object {' + $action.value + '}}'
      $scriptBlock = invoke-expression $exprString
      $btn.add_Click($scriptBlock)
      $btnPanel.Controls.Add($btn)
      $btnOffset += 100
      $btns += $btn
    }
  }

  # create the columns
  $lv.View = [System.Windows.Forms.View]"Details"
  $lv.Size = new-object System.Drawing.Size($width, 350)
  $lv.FullRowSelect = $true
  $lv.GridLines = $true
  $lv.Dock = "Fill"
  foreach ($col in $columnNames) {
    $lv.Columns.Add($col, 200) > $null
  }

  # populate the view
  foreach ($d in $data) {
    $item =
      new-object System.Windows.Forms.ListViewItem(
        invoke-expression ('$d.' + $columnProperties[0]))

    for ($i = 1; $i -lt $columnProperties.Count; $i++) {
      $item.SubItems.Add(
        (invoke-expression ('$d.' + $columnProperties[$i]))) > $null
    }
    $item.Tag = $d
    $lv.Items.Add($item) > $null
  }

  # display it
  $form.Add_Shown( { $form.Activate() } )
  if ($btns.Count -gt 0) {
    $form.AcceptButton = $btns[0]
  }
  $form.showdialog()
}

