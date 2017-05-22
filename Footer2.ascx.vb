Option Explicit On 
Option Strict On

Imports CS.CSDataHelpers.Helpers

Namespace Controls

    Public Class Footer2
        Inherits System.Web.UI.UserControl

#Region " Private Variables "

        Private _auth As CS.CSSecurity.Authenticate
        Private _dtWebBrandCache As DataTable

#End Region

#Region " Public Properties "

        Public ReadOnly Property RootName() As String
            Get
                Return CS.CSUI.ConfigInfo.RootName
            End Get
        End Property

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

        Private Property WebBrandCache() As DataTable
            Get
                Return Me._dtWebBrandCache
            End Get
            Set(ByVal value As DataTable)
                Me._dtWebBrandCache = value
            End Set
        End Property

#End Region

#Region " Page Event Handlers "

        Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
            Dim mySB As New System.Text.StringBuilder
            Dim myFAQ As New System.Text.StringBuilder
            Dim mySBGoogleAnalytics As New System.Text.StringBuilder

            Try
                If Me.Authenticate.IsAuthenticated Then
                    If Not Me.Authenticate.Brand = CS.CSEnums.Enums.Brand.ExpediaDotCom Then
                        Dim redirectSiteType As String

                        Me.WebBrandCache = CC.BusinessLogic.WebBrand.GetCacheWebBrand(Me.Page.Cache)

                        If Me.Authenticate.Brand = CS.CSEnums.Enums.Brand.CruiseShipCenters And Me.Authenticate.Currency = "CAD" Then
                            redirectSiteType = ".ca"
                        Else
                            redirectSiteType = ".com"
                        End If

                        'Add copyright
                        Me.litCopyright.Text = "&copy; 2003 - " & ConvertStrFromNull(Now.Year) & ", CruiseShipCenters International Inc."

                        With mySB
                            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.ADMN) Then
                                'Add email developers link
                                .Append(" <a href=""#"" onclick=""window.open('")
                                .Append(CS.CSUI.ConfigInfo.RootName)
                                .Append("/Purser/TaskPopup.aspx")
                                .Append("?URL=")
                                .Append(Replace(Page.Server.UrlEncode(Page.Request.Url.ToString), "'", "&rsquo;"))
                                .Append("','Task','width=650,height=300,resizable=no,scrollbars=yes,toolbar=no,titlebar=no,addressbar=no')"" class=""linkSmall"">Email Developers")
                                .Append("</a>")
                                .Append(" | ")
                            End If

                            'Add email Partner Support link
                            .Append(" <a href=""#"" onclick=""window.open('")
                            .Append(CS.CSUI.ConfigInfo.GetURL("", CS.CSUI.Helpers.FindBrandTypeByBrand(Me.Authenticate.Brand.ToString, Me.WebBrandCache()), redirectSiteType, False) & CS.CSUI.ConfigInfo.RootCSC)
                            .Append("/Feedback.aspx?csc=0")
                            .Append("&Web_ID=" & Me.Authenticate.Web_ID)
                            .Append("&URL=" & Replace(Page.Server.UrlEncode(Page.Request.Url.ToString), "'", "&rsquo;"))
                            .Append("&Role=" & Me.GetRole())
                            .Append("','Feedback','width=650,height=500,resizable=no,scrollbars=yes,toolbar=no,titlebar=no,addressbar=no')"" class=""linkSmall"">Email Partner Support")
                            .Append("</a>")
                        End With

                        Me.litHelpLinks.Text = mySB.ToString

                    End If
                End If

                'Added for Google Analytics
                With mySBGoogleAnalytics
                    If CS.CSUI.ConfigInfo.IsEcomProduction Then
                        .Append(GoogleAnalyticsLink("UA-3695687-15"))
                    End If
                    If CS.CSUI.ConfigInfo.IsCSCProduction Then
                        .Append(GoogleAnalyticsLink("UA-3695687-13"))
                    End If
                End With
                Me.litGoogleAnalytics.Text = mySBGoogleAnalytics.ToString()
            Catch ex As Exception
                Me.LocalWriteLog(ex, "Page_Load")
            End Try
        End Sub

#End Region

#Region " Private Methods "

        Private Function GoogleAnalyticsLink(ByVal aAccountNo As String) As String
            Dim mySB As New System.Text.StringBuilder
            With mySB
                .Append("<script type=""text/javascript"">")
                .Append("var gaJsHost = ((""https:"" == document.location.protocol) ? ""https://ssl."" : ""http://www."");")
                .Append("document.write(unescape(""%3Cscript src='"" + gaJsHost + ""google-analytics.com/ga.js' ")
                .Append("type='text/javascript'%3E%3C/script%3E""));</script><script type=""text/javascript"">")
                .Append("try {var pageTracker = _gat._getTracker(""" & aAccountNo & """);pageTracker._trackPageview();} catch(err) {}</script>")
            End With
            Return mySB.ToString
        End Function

        Private Function GetRole() As String
            If (Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.OWNR)) Then
                Return "Owner"
            ElseIf (Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT)) Then
                Return "Consultant"
            ElseIf (Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.MNGR)) Then
                Return "Manager"
            ElseIf (Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CRSF)) Then
                Return "Corporate Staff"
            Else
                Return "Other"
            End If
        End Function

        Private Sub LocalWriteLog( _
            ByVal ex As Exception, _
            ByVal subName As String)

            CS.CSUI.ErrorHandler.WriteLog( _
                    ex, _
                    CS.CSUI.Helpers.CurrentProjectNameAsEnum(Me.Page.Application), _
                    CS.CSUI.Helpers.CurrentPageName() & " - " & subName, _
                    System.Web.HttpContext.Current.Request.Url.Query, _
                    CStr(Me.Authenticate.Web_ID))
        End Sub

#End Region

    End Class

End Namespace