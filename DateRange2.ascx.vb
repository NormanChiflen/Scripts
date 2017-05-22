Option Explicit On
Option Strict On

Imports CS.CSEnums

Namespace Controls

    ''' <summary>
    ''' Date Range Control
    ''' </summary>
    ''' <remarks>This control requires the ../Resource/JSCTO.js script.</remarks>
    Public Class DateRange2
        Inherits System.Web.UI.UserControl


#Region " Web Form Designer Generated Code "

        'This call is required by the Web Form Designer.
        <System.Diagnostics.DebuggerStepThrough()> Private Sub InitializeComponent()

        End Sub

        'NOTE: The following placeholder declaration is required by the Web Form Designer.
        'Do not delete or move it.
        Private designerPlaceholderDeclaration As System.Object

        Private Sub Page_Init(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Init
            'CODEGEN: This method call is required by the Web Form Designer
            'Do not modify it using the code editor.
            InitializeComponent()

            ' set the defaults
            InitializeControls()
        End Sub

#End Region

#Region " Constants "
        Private Const STARTUP_SCRIPT As String = "<script language=""javascript"" type=""text/javascript"" >" _
        + "window.attachEvent('onload', function(){HideShowDateRangeControl('%CONTROL_NAME%')});" _
        + "</script>"

        '+ "AddWindowOnLoad(""HideShowDateRangeControl('%CONTROL_NAME%')"");" _
#End Region

#Region " Enumerations "

        Public Enum DateRange
            <FieldsInfo("Year")> YEAR
            <FieldsInfo("Month")> MONTH
            <FieldsInfo("Day")> DAY
            <FieldsInfo("Range")> DR
        End Enum

        Public Enum DaySelection
            <FieldsInfo("Today")> TODAY
            <FieldsInfo("Yesterday")> YESTERDAY
            <FieldsInfo("Last Week")> LAST_WEEK
        End Enum

        Public Enum MonthSelection
            <FieldsInfo("Last Month")> LM
            <FieldsInfo("This Month")> TM
            <FieldsInfo("Next Month")> NM
        End Enum

        Public Enum YearSelection
            <FieldsInfo("Last Year")> LY
            <FieldsInfo("This Year")> TY
            <FieldsInfo("Next Year")> NY
            <FieldsInfo("Last 12 Months")> LAST_12_MONTHS
            <FieldsInfo("Year To Date")> YEAR_TO_DATE
        End Enum

        Public Enum RangeSelection
            <FieldsInfo("Range")> DR
        End Enum

#End Region


#Region " Private Members "
        Private _auth As CS.CSSecurity.Authenticate
#End Region

#Region " Private Properties "

        Private ReadOnly Property Authenticate() As CS.CSSecurity.Authenticate
            Get
                If Me._auth Is Nothing Then
                    Me._auth = New CS.CSSecurity.Authenticate
                End If
                Return Me._auth
            End Get
        End Property

        Private ReadOnly Property ListDateRange() As ListItemCollection
            Get
                Dim localList As New ListItemCollection
                Dim strValue As String
                Dim enumValue As DateRange
                Dim arrEnum As String() = System.Enum.GetNames(GetType(DateRange))

                ' loop through the enumeration and create the ListItemCollection
                For Each strValue In arrEnum
                    enumValue = CType(System.Enum.Parse(GetType(DateRange), strValue), DateRange)
                    localList.Add(New ListItem(CS.CSEnums.AttributeUtility.GetDBFieldName(enumValue), strValue))
                Next

                Return localList
            End Get
        End Property

        Private ReadOnly Property ListYearSelection() As ListItemCollection
            Get
                Dim localList As New ListItemCollection
                Dim strValue As String
                Dim enumValue As YearSelection
                Dim arrEnum As String() = System.Enum.GetNames(GetType(YearSelection))

                ' loop through the enumeration and create the ListItemCollection
                For Each strValue In arrEnum
                    enumValue = CType(System.Enum.Parse(GetType(YearSelection), strValue), YearSelection)
                    localList.Add(New ListItem(CS.CSEnums.AttributeUtility.GetDBFieldName(enumValue), strValue))
                Next

                Return localList
            End Get
        End Property

        Private ReadOnly Property ListMonthSelection() As ListItemCollection
            Get
                Dim localList As New ListItemCollection
                Dim strValue As String
                Dim enumValue As MonthSelection
                Dim arrEnum As String() = System.Enum.GetNames(GetType(MonthSelection))

                ' loop through the enumeration and create the ListItemCollection
                For Each strValue In arrEnum
                    enumValue = CType(System.Enum.Parse(GetType(MonthSelection), strValue), MonthSelection)
                    localList.Add(New ListItem(CS.CSEnums.AttributeUtility.GetDBFieldName(enumValue), strValue))
                Next

                Return localList
            End Get
        End Property

        Private ReadOnly Property ListDaySelection() As ListItemCollection
            Get
                Dim localList As New ListItemCollection
                Dim strValue As String
                Dim enumValue As DaySelection
                Dim arrEnum As String() = System.Enum.GetNames(GetType(DaySelection))

                ' loop through the enumeration and create the ListItemCollection
                For Each strValue In arrEnum
                    enumValue = CType(System.Enum.Parse(GetType(DaySelection), strValue), DaySelection)
                    localList.Add(New ListItem(CS.CSEnums.AttributeUtility.GetDBFieldName(enumValue), strValue))
                Next

                Return localList
            End Get
        End Property

        Private ReadOnly Property ListRangeSelection() As ListItemCollection
            Get
                Dim localList As New ListItemCollection
                Dim strValue As String
                Dim enumValue As RangeSelection
                Dim arrEnum As String() = System.Enum.GetNames(GetType(RangeSelection))

                ' loop through the enumeration and create the ListItemCollection
                For Each strValue In arrEnum
                    enumValue = CType(System.Enum.Parse(GetType(RangeSelection), strValue), RangeSelection)
                    localList.Add(New ListItem(CS.CSEnums.AttributeUtility.GetDBFieldName(enumValue), strValue))
                Next

                Return localList
            End Get
        End Property

#End Region

#Region " Public Properties "

        Public Property PrimaryRangeType() As DateRange
            Get
                Dim myObj As Object = System.Enum.Parse(GetType(DateRange), Me.rblDateRange.SelectedValue)
                Dim myDateRange As DateRange = DirectCast(myObj, DateRange)
                Return myDateRange
            End Get
            Set(ByVal value As DateRange)
                Me.rblDateRange.SelectedIndex = value
            End Set
        End Property

        Public Property SecondayRangeType() As [Enum]
            Get
                Dim myObj As Object
                myObj = System.Enum.Parse(GetType(YearSelection), Me.rblYearSelection.SelectedValue)
                Dim myYearSelection As YearSelection = DirectCast(myObj, YearSelection)

                myObj = System.Enum.Parse(GetType(MonthSelection), Me.rblMonthSelection.SelectedValue)
                Dim myMonthSelection As MonthSelection = DirectCast(myObj, MonthSelection)

                myObj = System.Enum.Parse(GetType(DaySelection), Me.rblDaySelection.SelectedValue)
                Dim myDaySelection As DaySelection = DirectCast(myObj, DaySelection)

                myObj = System.Enum.Parse(GetType(RangeSelection), Me.rblRangeSelection.SelectedValue)
                Dim myRangeSelection As RangeSelection = DirectCast(myObj, RangeSelection)

                Select Case Me.PrimaryRangeType
                    Case DateRange.YEAR
                        Return myYearSelection
                    Case DateRange.MONTH
                        Return myMonthSelection
                    Case DateRange.DAY
                        Return myDaySelection
                    Case DateRange.DR
                        Return myRangeSelection
                    Case Else
                        Throw New ArgumentOutOfRangeException()
                End Select
            End Get
            Set(ByVal value As [Enum])
                If TypeOf value Is YearSelection Then
                    Me.rblYearSelection.SelectedValue = [Enum].GetName(value.GetType(), value)
                ElseIf TypeOf value Is MonthSelection Then
                    Me.rblMonthSelection.SelectedValue = [Enum].GetName(value.GetType(), value)
                ElseIf TypeOf value Is DaySelection Then
                    Me.rblDaySelection.SelectedValue = [Enum].GetName(value.GetType(), value)
                ElseIf TypeOf value Is RangeSelection Then
                    Me.rblRangeSelection.SelectedValue = [Enum].GetName(value.GetType(), value)
                Else
                    Throw New ArgumentOutOfRangeException()
                End If
            End Set
        End Property

        Public Function ConvertDateRange(ByVal myDateRangeText As String) As DateRange
            Dim myRetVal As DateRange
            Try
                myRetVal = CType(System.Enum.Parse(GetType(DateRange), myDateRangeText, True), DateRange)
            Catch ex As ArgumentException
                myRetVal = DateRange.DR
            End Try
            Return myRetVal
        End Function

        Public Property StartDate() As Date
            Get
                If IsDate(Me.hidStartDate.Value) Then
                    Return CDate(Me.hidStartDate.Value)
                Else
                    Return CDate(CS.CSUI.ConfigInfo.CSC_MINIMUM_DATE)
                End If
            End Get
            Set(ByVal Value As Date)
                If Value <> CDate(CS.CSUI.ConfigInfo.CSC_MINIMUM_DATE) Then
                    Me.dtbStartDate.Text = CStr(Value)
                Else
                    Me.dtbStartDate.Text = ""
                End If
                Me.hidStartDate.Value = Me.dtbStartDate.Text
            End Set
        End Property

        Public Property EndDate() As Date
            Get
                If IsDate(Me.hidEndDate.Value) Then
                    Return CDate(Me.hidEndDate.Value)
                Else
                    Return CDate(CS.CSUI.ConfigInfo.CSC_MINIMUM_DATE)
                End If
            End Get
            Set(ByVal Value As Date)
                If Value <> CDate(CS.CSUI.ConfigInfo.CSC_MINIMUM_DATE) Then
                    Me.dtbEndDate.Text = CStr(Value)
                Else
                    Me.dtbEndDate.Text = ""
                End If
                Me.hidEndDate.Value = Me.dtbEndDate.Text
            End Set
        End Property

        Public ReadOnly Property SelectedDateRange() As DateRange
            Get
                Return CType(System.Enum.Parse(GetType(DateRange), Me.rblDateRange.SelectedValue), DateRange)
            End Get
            'Set(ByVal Value As DateRange)
            '    Me.WriteDateRange(Value.ToString)
            'End Set
        End Property

#End Region

#Region " Page Event Handlers "




        Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
            Me.CDLite()

            If Me.Visible Then
                Me.Page.ClientScript.RegisterStartupScript(Me.GetType(), "StartupScript_" + Me.ClientID, STARTUP_SCRIPT.Replace("%CONTROL_NAME%", Me.ClientID))
            End If

            If Not Me.Page.IsPostBack Then
                Me.rblDateRange.Attributes.Add("onclick", "HideShowDateRangeControl('" & Me.ClientID & "');")
                Me.rblDaySelection.Attributes.Add("onclick", "HideShowDaySelections('" & Me.ClientID & "');")
                Me.rblMonthSelection.Attributes.Add("onclick", "HideShowMonthSelections('" & Me.ClientID & "');")
                Me.rblYearSelection.Attributes.Add("onclick", "HideShowYearSelections('" & Me.ClientID & "');")
            End If

            Me.dtbStartDate.Attributes.Add("onfocusout", "document.getElementById('" & hidStartDate.ClientID & "').value = this.value;")
            Me.dtbEndDate.Attributes.Add("onfocusout", "document.getElementById('" & hidEndDate.ClientID & "').value = this.value;")
        End Sub

#End Region

#Region " Private Methods "


        Private Sub CDLite()
            If Me.Authenticate.SiteMode = "lite" Then
                Me.dtbEndDate.xShowPopupB = False
                Me.dtbStartDate.xShowPopupB = False
                Me.dtbEndDate.xShowHelpButton = False
                Me.dtbStartDate.xShowHelpButton = False
            End If
        End Sub

        Private Sub InitializeControls()

            With Me.rblDateRange
                .DataSource = Me.ListDateRange
                .DataValueField = "Value"
                .DataTextField = "Text"
                .DataBind()
                .SelectedIndex = 0
            End With

            With Me.rblDaySelection
                .DataSource = Me.ListDaySelection
                .DataValueField = "Value"
                .DataTextField = "Text"
                .DataBind()
                .SelectedIndex = 0
            End With

            With Me.rblMonthSelection
                .DataSource = Me.ListMonthSelection
                .DataValueField = "Value"
                .DataTextField = "Text"
                .DataBind()
                If .SelectedValue = "" Then
                    .SelectedIndex = 1
                End If
            End With

            With Me.rblYearSelection
                .DataSource = Me.ListYearSelection
                .DataValueField = "Value"
                .DataTextField = "Text"
                .DataBind()
                .SelectedIndex = 1
            End With
            Me.StartDate = New Date(Now.Year(), 1, 1)
            Me.EndDate = New Date(Now.Year(), 12, 31)

            With Me.rblRangeSelection
                .DataSource = Me.ListRangeSelection
                .DataValueField = "Value"
                .DataTextField = "Text"
                .DataBind()
                .SelectedIndex = 0
            End With
        End Sub
#End Region

        Public Sub SetRangeType(ByVal aPrimaryRangeType As DateRange, ByVal aSecondaryRangeType As System.Enum, ByVal dateStart As DateTime, ByVal dateEnd As DateTime)
            Me.PrimaryRangeType = aPrimaryRangeType
            Select Case Me.PrimaryRangeType
                Case DateRange.YEAR
                    Me.SecondayRangeType = aSecondaryRangeType
                Case DateRange.MONTH
                    Me.SecondayRangeType = aSecondaryRangeType
                Case DateRange.DAY
                    Me.SecondayRangeType = aSecondaryRangeType
                Case DateRange.DR
                    Me.SecondayRangeType = aSecondaryRangeType
                    Me.StartDate = dateStart
                    Me.EndDate = dateEnd
                Case Else
                    Throw New ArgumentOutOfRangeException()
            End Select
        End Sub

        ''' <summary>
        ''' 
        ''' </summary>
        ''' <param name="primaryRangeType"></param>
        ''' <param name="secondaryRangeType"></param>
        ''' <param name="dateStart"></param>
        ''' <param name="dateEnd"></param>
        ''' <remarks>If parsing a querystring, use QueryStringValue[get/set] </remarks>
        Public Sub SetRangeType(ByVal primaryRangeType As String, ByVal secondaryRangeType As String, ByVal dateStart As DateTime, ByVal dateEnd As DateTime)
            Dim myObj As Object = [Enum].Parse(GetType(DateRange), primaryRangeType)
            Me.PrimaryRangeType = DirectCast(myObj, DateRange)
            Select Case Me.PrimaryRangeType
                Case DateRange.YEAR
                    myObj = [Enum].Parse(GetType(YearSelection), secondaryRangeType)
                    Me.SecondayRangeType = DirectCast(myObj, YearSelection)
                Case DateRange.MONTH
                    myObj = [Enum].Parse(GetType(MonthSelection), secondaryRangeType)
                    Me.SecondayRangeType = DirectCast(myObj, MonthSelection)
                Case DateRange.DAY
                    myObj = [Enum].Parse(GetType(DaySelection), secondaryRangeType)
                    Me.SecondayRangeType = DirectCast(myObj, DaySelection)
                Case DateRange.DR
                    myObj = [Enum].Parse(GetType(RangeSelection), secondaryRangeType)
                    Me.SecondayRangeType = DirectCast(myObj, RangeSelection)
                    Me.StartDate = dateStart
                    Me.EndDate = dateEnd
                Case Else
                    Throw New ArgumentOutOfRangeException()
            End Select


        End Sub

        ''' <summary>
        ''' 
        ''' </summary>
        ''' <param name="primaryRangeType"></param>
        ''' <param name="secondaryRangeType"></param>
        ''' <remarks>If parsing a querystring, use QueryStringValue[get/set] </remarks>
        Public Sub SetRangeType(ByVal primaryRangeType As String, ByVal secondaryRangeType As String)
            SetRangeType(primaryRangeType, secondaryRangeType, New Date(Now.Year, 1, 1), New Date(Now.Year, 12, 31, 23, 59, 59))
        End Sub




        Public Function QueryStringValueGet() As String
            Dim value As String

            If Me.PrimaryRangeType = DateRange.DR Then
                value = String.Join(":", New String() _
                    {Me.StartDate.ToString("yyyy-MM-dd") _
                    , Me.EndDate.ToString("yyyy-MM-dd")})
            Else
                value = String.Join(":", New String() _
                {Me.PrimaryRangeType.ToString() _
                , Me.SecondayRangeType.ToString()})
            End If

            value = System.Web.HttpUtility.UrlEncode(value)

            Return value
        End Function

        Public Sub QueryStringValueSet(ByVal value As String)

            value = System.Web.HttpUtility.UrlDecode(value)
            Dim valueArray() As String = value.Split(New String() {":"}, StringSplitOptions.RemoveEmptyEntries)

            If (valueArray.Length = 2) Then
                Dim isConstant As Boolean = False
                Dim isDateRange As Boolean = False
                Dim dtStart As DateTime
                Dim dtEnd As DateTime

                'test for DateRange constants
                isConstant = isConstant Or System.Enum.IsDefined(GetType(YearSelection), valueArray(1))
                isConstant = isConstant Or System.Enum.IsDefined(GetType(MonthSelection), valueArray(1))
                isConstant = isConstant Or System.Enum.IsDefined(GetType(DaySelection), valueArray(1))
                isConstant = isConstant And System.Enum.IsDefined(GetType(DateRange), valueArray(0))

                If isConstant Then
                    Me.PrimaryRangeType = DirectCast(System.Enum.Parse(GetType(DateRange), valueArray(0)), DateRange)
                    Select Case (Me.PrimaryRangeType)
                        Case DateRange.YEAR
                            Me.SecondayRangeType = DirectCast(System.Enum.Parse(GetType(YearSelection), valueArray(1)), YearSelection)
                            Return
                        Case DateRange.MONTH
                            Me.SecondayRangeType = DirectCast(System.Enum.Parse(GetType(MonthSelection), valueArray(1)), YearSelection)
                            Return
                        Case DateRange.DAY
                            Me.SecondayRangeType = DirectCast(System.Enum.Parse(GetType(DaySelection), valueArray(1)), YearSelection)
                            Return
                    End Select
                    Return
                End If


                'test for start & end date
                isDateRange = DateTime.TryParse(valueArray(0), dtStart)
                isDateRange = isDateRange And DateTime.TryParse(valueArray(1), dtEnd)

                If isDateRange Then
                    If dtStart <= dtEnd Then
                        Me.PrimaryRangeType = DateRange.DR
                        Me.SecondayRangeType = RangeSelection.DR
                        Me.StartDate = dtStart
                        Me.EndDate = dtEnd
                        Return
                    End If
                End If
            End If

            Throw New ArgumentException()
        End Sub
    End Class

End Namespace

