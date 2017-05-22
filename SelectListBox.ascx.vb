Option Explicit On
Option Strict On

Imports System
Imports System.Web
Imports System.Web.UI
Imports System.Web.UI.WebControls
Imports System.Data


Namespace Controls
    Partial Public Class SelectListBox
        Inherits System.Web.UI.UserControl

#Region " Private Variables "

        Private _availableItemText As String = "Available"
        Private _addedItemText As String = "Selected"
        Private _dataTextFieldAvailable As String = String.Empty
        Private _dataValueFieldAvailable As String = String.Empty
        Private _dataTextFieldAdded As String = String.Empty
        Private _dataValueFieldAdded As String = String.Empty
        Private _addSelectedItemButtonText As String = "Add >"
        Private _addAllItemsButtonText As String = "Add All >>"
        Private _removeSelectedItemButtonText As String = "< Remove"
        Private _removeAllItemsButtonText As String = "<< Remove All"
        Private _availableListSelectionMode As ListSelectionMode = ListSelectionMode.Multiple
        Private _addedItemsListSelectionMode As ListSelectionMode = ListSelectionMode.Multiple
        Private _datatableAvaialable As DataTable
        Private _datatableAdded As DataTable
        Protected arlList As New ArrayList()
        Private _listboxAddedRows As Integer
        Private _listboxAvailable As ListBox


      

#End Region

#Region " Public Properties "

        Public Property ListBoxAddedRows() As Integer
            Get
                Return lstAdded.Rows
            End Get
            Set(ByVal value As Integer)
                lstAdded.Rows = value
            End Set
        End Property
        Public Property ListBoxAddedWidth() As Unit
            Get
                Return lstAdded.Width
            End Get
            Set(ByVal value As Unit)
                lstAdded.Width = value
            End Set
        End Property
        Public Property ListBoxAvailableRows() As Integer
            Get
                Return lstAvailable.Rows
            End Get
            Set(ByVal value As Integer)
                lstAvailable.Rows = value
            End Set
        End Property
        Public Property ListBoxAvailableWidth() As Unit
            Get
                Return lstAvailable.Width
            End Get
            Set(ByVal value As Unit)
                lstAvailable.Width = value
            End Set
        End Property

        ''' <summary>
        ''' Gets the available items.
        ''' </summary>
        ''' <value>The available items.</value>
        Public ReadOnly Property AvailableItems() As ListItemCollection
            Get
                Return lstAvailable.Items
            End Get
        End Property

        ''' <summary>
        ''' Gets the added items.
        ''' </summary>
        ''' <value>The added items.</value>
        Public ReadOnly Property AddedItems() As ListItemCollection
            Get
                Return lstAdded.Items
            End Get
        End Property

        ''' <summary>
        ''' Gets or sets the available item text.
        ''' </summary>
        ''' <value>The available item text.</value>
        Public Property AvailableItemText() As String
            Get
                Return _availableItemText
            End Get
            Set(ByVal value As String)
                _availableItemText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the added items text.
        ''' </summary>
        ''' <value>The added items text.</value>
        Public Property AddedItemsText() As String
            Get
                Return _addedItemText
            End Get
            Set(ByVal value As String)
                _addedItemText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the 'Add Selected Item' button text.
        ''' </summary>
        ''' <value>The 'Add Selected Item' button text.</value>
        Public Property AddAllItemsButtonText() As String
            Get
                Return _addAllItemsButtonText
            End Get
            Set(ByVal value As String)
                _addAllItemsButtonText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the add select all button text.
        ''' </summary>
        ''' <value>The add select all button text.</value>
        Public Property AddSelectedItemsButtonText() As String
            Get
                Return _addSelectedItemButtonText
            End Get
            Set(ByVal value As String)
                _addSelectedItemButtonText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the remove selected item button text.
        ''' </summary>
        ''' <value>The remove selected item button text.</value>
        Public Property RemoveSelectedItemButtonText() As String
            Get
                Return _removeSelectedItemButtonText
            End Get
            Set(ByVal value As String)
                _removeSelectedItemButtonText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the remove all items button text.
        ''' </summary>
        ''' <value>The remove all items button text.</value>
        Public Property RemoveAllItemsButtonText() As String
            Get
                Return _removeAllItemsButtonText
            End Get
            Set(ByVal value As String)
                _removeAllItemsButtonText = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the available list selection mode.
        ''' </summary>
        ''' <value>The available list selection mode.</value>
        Public Property AvailableListSelectionMode() As ListSelectionMode
            Get
                Return _availableListSelectionMode
            End Get
            Set(ByVal value As ListSelectionMode)
                _availableListSelectionMode = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the added items list selection mode.
        ''' </summary>
        ''' <value>The added items list selection mode.</value>
        Public Property AddedItemsListSelectionMode() As ListSelectionMode
            Get
                Return _addedItemsListSelectionMode
            End Get
            Set(ByVal value As ListSelectionMode)
                _addedItemsListSelectionMode = value
            End Set
        End Property

        Public Property DataSourceAvailable() As DataTable
            Get

                '_datatable.DefaultView.Sort = Me.DataValueFieldAvailable
                Return _datatableAvaialable
            End Get
            Set(ByVal value As DataTable)
                _datatableAvaialable = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the data source for the added items listbox.
        ''' </summary>
        ''' <value>The data source for added items.</value>
        Public Property DataSourceAdded() As DataTable
            Get
                Return _datatableAdded
            End Get
            Set(ByVal value As DataTable)
                _datatableAdded = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the data text field available.
        ''' </summary>
        ''' <value>The data text field available.</value>
        Public Property DataTextFieldAvailable() As String
            Get
                Return _dataTextFieldAvailable
            End Get
            Set(ByVal value As String)
                _dataTextFieldAvailable = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the data value field available.
        ''' </summary>
        ''' <value>The data value field available.</value>
        Public Property DataValueFieldAvailable() As String
            Get
                Return _dataValueFieldAvailable
            End Get
            Set(ByVal value As String)
                _dataValueFieldAvailable = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the data text field added.
        ''' </summary>
        ''' <value>The data text field added.</value>
        Public Property DataTextFieldAdded() As String
            Get
                Return _dataTextFieldAdded
            End Get
            Set(ByVal value As String)
                _dataTextFieldAdded = value
            End Set
        End Property

        ''' <summary>
        ''' Gets or sets the data value field added.
        ''' </summary>
        ''' <value>The data value field added.</value>
        Public Property DataValueFieldAdded() As String
            Get
                Return _dataValueFieldAdded
            End Get
            Set(ByVal value As String)
                _dataValueFieldAdded = value
            End Set
        End Property

        'property that returns id in added list
        Public ReadOnly Property SelectedItems() As String
            Get
                Return GetList()
            End Get
        End Property

#End Region

#Region " Event Handlers "

        ''' <summary>
        ''' Handles the Load event of the Page control.
        ''' </summary>
        ''' <param name="sender">The source of the event.</param>
        ''' <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        Protected Sub Page_Load(ByVal sender As Object, ByVal e As EventArgs) Handles Me.Load

        End Sub

        ''' <summary>
        ''' Sets the control properties.
        ''' </summary>
        Public Sub BindControl()
            'Set the Header Text of the Available and Added Items
            lblAdded.Text = Me.AddedItemsText
            lblAvailable.Text = Me.AvailableItemText

            'Bind the Available and Added List Controls

            lstAdded.DataSource = Me.DataSourceAdded
            lstAdded.DataTextField = Me.DataTextFieldAdded
            lstAdded.DataValueField = Me.DataValueFieldAdded
            lstAdded.DataBind()

            lstAvailable.DataSource = Me.DataSourceAvailable
            lstAvailable.DataTextField = Me.DataTextFieldAvailable
            lstAvailable.DataValueField = Me.DataValueFieldAvailable
            lstAvailable.DataBind()

            'Set the Button Text
            btnAdd.Text = Me.AddSelectedItemsButtonText
            btnAddAll.Text = Me.AddAllItemsButtonText
            btnRemove.Text = Me.RemoveSelectedItemButtonText
            btnRemoveAll.Text = Me.RemoveAllItemsButtonText

            'Set the SelectionMode of the ListItems
            lstAvailable.SelectionMode = Me.AvailableListSelectionMode
            lstAdded.SelectionMode = Me.AddedItemsListSelectionMode

        End Sub

        ''' <summary>
        ''' Add all the selected items from the Available Items to the Added Items
        ''' </summary>
        ''' <param name="sender">The source of the event.</param>
        ''' <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        Protected Sub btnAdd_Click(ByVal sender As Object, ByVal e As EventArgs)
            If lstAvailable.SelectedIndex >= 0 Then
                For i As Integer = 0 To lstAvailable.Items.Count - 1
                    If lstAvailable.Items(i).Selected Then
                        If Not arlList.Contains(lstAvailable.Items(i)) Then
                            arlList.Add(lstAvailable.Items(i))
                        End If
                    End If
                Next
                For i As Integer = 0 To arlList.Count - 1
                    If Not lstAdded.Items.Contains(DirectCast(arlList(i), ListItem)) Then
                        lstAdded.Items.Add(DirectCast(arlList(i), ListItem))
                    End If
                    lstAvailable.Items.Remove(DirectCast(arlList(i), ListItem))
                Next
            Else
                'lblError.Text = "Select item to add"
            End If
        End Sub

        ''' <summary>
        ''' Add all the items from the Available items to the Added Items
        ''' </summary>
        ''' <param name="sender">The source of the event.</param>
        ''' <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        Protected Sub btnAddAll_Click(ByVal sender As Object, ByVal e As EventArgs) Handles btnAddAll.Click

            For Each list As ListItem In lstAvailable.Items
                lstAdded.Items.Add(list)
            Next
            lstAvailable.Items.Clear()


        End Sub

        ''' <summary>
        ''' Moves the Selected items from the Added items to the Available items
        ''' </summary>
        ''' <param name="sender">The source of the event.</param>
        ''' <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        Protected Sub btnRemove_Click(ByVal sender As Object, ByVal e As EventArgs)
            If lstAdded.SelectedIndex >= 0 Then
                For i As Integer = 0 To lstAdded.Items.Count - 1
                    If lstAdded.Items(i).Selected Then
                        If Not arlList.Contains(lstAdded.Items(i)) Then
                            arlList.Add(lstAdded.Items(i))
                        End If
                    End If
                Next
                For i As Integer = 0 To arlList.Count - 1
                    If Not lstAvailable.Items.Contains(DirectCast(arlList(i), ListItem)) Then
                        lstAvailable.Items.Add(DirectCast(arlList(i), ListItem))
                    End If
                    lstAdded.Items.Remove(DirectCast(arlList(i), ListItem))
                Next
            Else
                'lblError.Text = "Select item to remove"
            End If
        End Sub

        ''' <summary>
        ''' Moves all the items from the Added items to the Available items
        ''' </summary>
        ''' <param name="sender">The source of the event.</param>
        ''' <param name="e">The <see cref="System.EventArgs"/> instance containing the event data.</param>
        Protected Sub btnRemoveAll_Click(ByVal sender As Object, ByVal e As EventArgs) Handles btnRemoveAll.Click

            For Each list As ListItem In lstAdded.Items
                lstAvailable.Items.Add(list)
            Next
            lstAdded.Items.Clear()

        End Sub

        Private Function GetList() As String

            Dim item As ListItem
            Dim iString As String = vbNullString

            iString = vbNullString
            For Each item In lstAdded.Items
                iString += item.Value + ","
            Next

            If iString <> vbNullString Then iString = Left(iString, iString.Length - 1)

            Return iString

        End Function

#End Region

    End Class
End Namespace


