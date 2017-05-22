Option Strict On
Option Explicit On 

Imports CT.BusinessLogic.Revenue

Namespace Controls

Public Class YearByYear
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
    End Sub

#End Region

#Region " Protected Controls "

        Protected WithEvents lblReportUser As System.Web.UI.WebControls.Label
        Protected WithEvents lblReportTitle1 As System.Web.UI.WebControls.Label
        Protected WithEvents lblReportTitle As System.Web.UI.WebControls.Label

        Protected WithEvents dgrBookedYearByYear As System.Web.UI.WebControls.DataGrid
        Protected WithEvents dgrRevenueYearByYear As System.Web.UI.WebControls.DataGrid

#End Region

#Region " Enumerations "

        Enum gridBookedYearByYear
            MonthName
            Year02
            Year03
            Year04
            Year05
            Year06
        End Enum

        Enum gridRevenueYearByYear
            MonthName
            Year02
            Year03
            Year04
            Year05
            Year06
            Year07
        End Enum

#End Region

#Region " Private Variables "
        Private _reportValid As Boolean = False
#End Region

#Region " Public Properties "

        Public Property ReportValid() As Boolean
            Get
                Return Me._reportValid
            End Get
            Set(ByVal Value As Boolean)
                Me._reportValid = Value
            End Set
        End Property

#End Region

#Region " Page Event Handlers "

        Private Sub Page_Load(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles MyBase.Load
        End Sub

#End Region

#Region " Public Methods "

        Public Sub RunReport(ByVal aWebID As Integer, _
                            ByVal aSelectedWebID As Integer, _
                            ByVal aSelectedSecurityType As String, _
                            ByVal aSupplier As String, _
                            ByVal aWholesaler As String, _
                            ByVal aCTOType As String, _
                            ByVal aCenterName As String)

            Dim myDT As DataTable
            Dim mySB As New System.Text.StringBuilder
            Dim myShowReport As Boolean
            Dim myStartYear As Integer

            myStartYear = Now().Year - 4

            With Me.dgrBookedYearByYear
                .Columns(gridBookedYearByYear.MonthName).HeaderText = "Month"
                .Columns(gridBookedYearByYear.Year02).HeaderText = CStr(myStartYear)
                .Columns(gridBookedYearByYear.Year03).HeaderText = CStr(myStartYear + 1)
                .Columns(gridBookedYearByYear.Year04).HeaderText = CStr(myStartYear + 2)
                .Columns(gridBookedYearByYear.Year05).HeaderText = CStr(myStartYear + 3)
                .Columns(gridBookedYearByYear.Year06).HeaderText = CStr(myStartYear + 4)
            End With

            With Me.dgrRevenueYearByYear
                .Columns(gridRevenueYearByYear.MonthName).HeaderText = "Month"
                .Columns(gridRevenueYearByYear.Year02).HeaderText = CStr(myStartYear)
                .Columns(gridRevenueYearByYear.Year03).HeaderText = CStr(myStartYear + 1)
                .Columns(gridRevenueYearByYear.Year04).HeaderText = CStr(myStartYear + 2)
                .Columns(gridRevenueYearByYear.Year05).HeaderText = CStr(myStartYear + 3)
                .Columns(gridRevenueYearByYear.Year06).HeaderText = CStr(myStartYear + 4)
                .Columns(gridRevenueYearByYear.Year07).HeaderText = CStr(myStartYear + 5)
            End With

            myDT = CT.BusinessLogic.Revenue.ReadReportYearOverYear(aWebID, _
                                                                    aSelectedWebID, _
                                                                    aSelectedSecurityType, _
                                                                    "Revenue", _
                                                                    aCTOType, _
                                                                    aWholesaler, _
                                                                    aSupplier, _
                                                                    myStartYear)
            myShowReport = (myDT.Rows.Count > 0)

            If myShowReport Then
                With Me.dgrRevenueYearByYear
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

            myDT = CT.BusinessLogic.Revenue.ReadReportYearOverYear(aWebID, _
                                                                    aSelectedWebID, _
                                                                    aSelectedSecurityType, _
                                                                    "Booked", _
                                                                    aCTOType, _
                                                                    aWholesaler, _
                                                                    aSupplier, _
                                                                    myStartYear)
            myShowReport = (myDT.Rows.Count > 0) Or myShowReport

            If myShowReport Then
                With Me.dgrBookedYearByYear
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

            With mySB
                .Append("Year over Year Analysis for : ")
                .Append(aCenterName)
                If aSupplier.Length > 0 Then
                    .Append("<br>Supplier : ")
                    .Append(aSupplier)
                End If
                If aWholesaler.Length > 0 Then
                    .Append("<br>Wholesaler : ")
                    .Append(aWholesaler)
                End If
                If aCTOType.Length > 0 Then
                    .Append("<br>Product Type : ")
                    .Append(aCTOType)
                End If
                Me.lblReportUser.Text = .ToString
            End With

            Me.ReportValid = myShowReport

        End Sub

        Public Function IntNoDecimal(ByVal aNumber As Object) As String
            Return Format(CS.CSDataHelpers.Helpers.ConvertIntFromNull(aNumber), "###,###,###")
        End Function

#End Region

End Class

End Namespace