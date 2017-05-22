Option Explicit On
Option Strict On

Imports CS.CSEnums

Public Class Group_Result
    Inherits System.Web.UI.UserControl


#Region " Private Variables "

    Private _groupResultVal As String = ""

#End Region

#Region " Public Properties "

    Public Property GroupResultValue() As String
        Get
            Return _groupResultVal
        End Get
        Set(ByVal value As String)
            _groupResultVal = value
        End Set
    End Property

#End Region

#Region " Page Event Handlers "

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load

    End Sub

    Protected Sub rdGroupResult_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdGroupResult.SelectedIndexChanged
        If rdGroupResult.SelectedValue = "Yes" Then
            pnlGroupResult.Visible = True
        Else
            pnlGroupResult.Visible = False
        End If
    End Sub

    Protected Sub rdGroupResultYes_SelectedIndexChanged(ByVal sender As System.Object, ByVal e As System.EventArgs) Handles rdGroupResultYes.SelectedIndexChanged
        GroupResultValue = rdGroupResultYes.SelectedValue
    End Sub

#End Region

End Class