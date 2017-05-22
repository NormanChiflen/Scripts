Option Strict On
Option Explicit On

Namespace Controls

    Partial Public Class PromotionHeader
        Inherits System.Web.UI.UserControl

        Public Event HeaderSelectedSecurityTypeChange()

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

#Region " Private Variables "

        Private _auth As CS.CSSecurity.Authenticate
        Private _timerLength As Integer
        Private _centerID As Integer
        Private _webID As Integer
        Private _userID As Integer
        Private _reportType As String
        Private _reportTypeLink As String

        Private _centerHBID As Integer
        Private _webHBID As Integer
        Private _userHBID As Integer
        Private _reportTypeLinkHB As String
        Private Const _defaultReportTypeEAC As String = "EuropeAlaskaCustomers"
        Private Const _defaultReportTypeSTC As String = "IdealProspects"
        Private Const _defaultReportTypeOthers As String = "Prospects"
#End Region

#Region " Properties "

        Private ReadOnly Property Authenticate() As CS.CSSecurity.Authenticate
            Get
                If Me._auth Is Nothing Then
                    Me._auth = New CS.CSSecurity.Authenticate
                End If
                Return Me._auth
            End Get
        End Property

        Private ReadOnly Property DefaultReportTypeEAC() As String
            Get
                Return _defaultReportTypeEAC
            End Get
        End Property

        Private ReadOnly Property DefaultReportTypeSTC() As String
            Get
                Return _defaultReportTypeSTC
            End Get
        End Property

        Private ReadOnly Property DefaultReportTypeOthers() As String
            Get
                Return _defaultReportTypeOthers
            End Get
        End Property

        Private Property TimerLength() As Integer
            Get
                Return Me._timerLength
            End Get
            Set(ByVal value As Integer)
                Me._timerLength = value
            End Set
        End Property

        Private Property Center_ID() As Integer
            Get
                Return Me._centerID
            End Get
            Set(ByVal value As Integer)
                Me._centerID = value
            End Set
        End Property

        Private Property Web_ID() As Integer
            Get
                Return CType(ViewState("Web_ID"), Integer)
            End Get
            Set(ByVal value As Integer)
                ViewState("Web_ID") = value
            End Set
        End Property

        Private Property User_ID() As Integer
            Get
                Return Me._userID
            End Get
            Set(ByVal value As Integer)
                Me._userID = value
            End Set
        End Property

        Private Property ReportType() As String
            Get
                Return CType(ViewState("ReportType"), String)
            End Get
            Set(ByVal value As String)
                ViewState("ReportType") = value
            End Set
        End Property

        Private Property ReportTypeLink() As String
            Get
                Return Me._reportTypeLink
            End Get
            Set(ByVal value As String)
                Me._reportTypeLink = value
            End Set
        End Property

        Private Property CenterHB_ID() As Integer
            Get
                Return Me._centerHBID
            End Get
            Set(ByVal value As Integer)
                Me._centerHBID = value
            End Set
        End Property

        Private Property WebHB_ID() As Integer
            Get
                Return Me._webHBID
            End Get
            Set(ByVal value As Integer)
                Me._webHBID = value
            End Set
        End Property

        Private Property UserHB_ID() As Integer
            Get
                Return Me._userHBID
            End Get
            Set(ByVal value As Integer)
                Me._userHBID = value
            End Set
        End Property

        Private Property ReportTypeLinkHB() As String
            Get
                Return Me._reportTypeLinkHB
            End Get
            Set(ByVal value As String)
                Me._reportTypeLinkHB = value
            End Set
        End Property

        Public Property UserCount() As Integer
            Get
                Return CType(ViewState("UserCount"), Integer)
            End Get
            Set(ByVal value As Integer)
                ViewState("UserCount") = value
            End Set
        End Property

        Private Property PromotionType() As String
            Get
                Return CType(ViewState("PromotionType"), String)
            End Get
            Set(ByVal value As String)
                ViewState("PromotionType") = value
            End Set
        End Property

        Public Property SelectedSecurityType() As String
            Get
                Return CType(ViewState("SelectedSecurityType"), String)
            End Get
            Set(ByVal value As String)
                ViewState("SelectedSecurityType") = value
            End Set
        End Property

#End Region

#Region " Page Event Handlers "

        Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
            Me.pnlSeasToday.Visible = True
        End Sub

        'Private Sub rptHeaderOneDaySale_ItemDataBound(ByVal sender As Object, ByVal e As System.Web.UI.WebControls.RepeaterItemEventArgs) Handles rptHeaderOneDaySale.ItemDataBound
        '    Try
        '        Dim myLabel As Label
        '        Dim myDataRowView As DataRowView
        '        Dim myPercentage As Integer
        '        Dim myTableCell As Web.UI.HtmlControls.HtmlTableCell

        '        If (e.Item.ItemType = ListItemType.AlternatingItem Or e.Item.ItemType = ListItemType.Item) Then
        '            myDataRowView = CType(e.Item.DataItem, DataRowView)
        '            myPercentage = CS.CSDataHelpers.Helpers.ConvertIntFromNull(myDataRowView("FCCPercentage"))
        '            myLabel = CType(e.Item.FindControl("lblFCPercentage"), Label)
        '            myLabel.Text = Me.CalculatePercentage(myPercentage)

        '            myPercentage = CS.CSDataHelpers.Helpers.ConvertIntFromNull(myDataRowView("PastRCICustomers"))
        '            myLabel = CType(e.Item.FindControl("lblPastRCICustomerPercentage"), Label)
        '            myLabel.Text = Me.CalculatePercentage(myPercentage)

        '            myPercentage = CS.CSDataHelpers.Helpers.ConvertIntFromNull(myDataRowView("IDPrsPercentage"))
        '            myLabel = CType(e.Item.FindControl("lblIDPrsPercentage"), Label)
        '            myLabel.Text = Me.CalculatePercentage(myPercentage)

        '            myPercentage = CS.CSDataHelpers.Helpers.ConvertIntFromNull(myDataRowView("PROPercentage"))
        '            myLabel = CType(e.Item.FindControl("lblPROPercentage"), Label)
        '            myLabel.Text = Me.CalculatePercentage(myPercentage)

        '            myTableCell = CType(e.Item.FindControl("tdIPCPercentage"), Web.UI.HtmlControls.HtmlTableCell)
        '            myTableCell.Visible = Not Me.Authenticate.Country.ToLower = "us"

        '            myLabel = CType(e.Item.FindControl("lblCenterLabel"), Label)

        '            If CS.CSDataHelpers.Helpers.ConvertStrFromNull(myDataRowView("FullName")) = "Heading" Then
        '                myLabel.Text = "Center"
        '            Else
        '                myLabel.Text = CS.CSDataHelpers.Helpers.ConvertStrFromNull(myDataRowView("FullName"))
        '            End If

        '            Me.TimerLength = CS.CSDataHelpers.Helpers.ConvertIntFromNull(myDataRowView("TimerLength"))

        '        End If
        '    Catch ex As Exception

        '    End Try
        'End Sub

        Private Sub rblSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
            Handles rblSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblSecurityType.SelectedValue

                Me.LoadHeaderWorldExplorer( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub

        Private Sub rblSTCSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
            Handles rblSTCSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblSTCSecurityType.SelectedValue

                Me.LoadHeaderSeasToday( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblSTCSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub

        Private Sub rblEECSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
            Handles rblEECSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblEECSecurityType.SelectedValue

                Me.LoadHeaderEEC( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblEECSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub

        Private Sub rblEACSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
            Handles rblEACSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblEACSecurityType.SelectedValue

                Me.LoadHeaderEAC( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblEACSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub

        Private Sub rblSSCSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
            Handles rblSSCSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblSSCSecurityType.SelectedValue

                Me.LoadHeaderSSC( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblSSCSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub

        Private Sub rblLRCSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
            Handles rblLRCSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblLRCSecurityType.SelectedValue

                Me.LoadHeaderLRC( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblLRCSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub
        Private Sub rblOSCSecurityType_SelectedIndexChanged(ByVal sender As Object, ByVal e As System.EventArgs) _
          Handles rblOSCSecurityType.SelectedIndexChanged
            Try
                Me.SelectedSecurityType = rblOSCSecurityType.SelectedValue

                Me.LoadHeaderOSC( _
                    Me.ReportType, _
                    Me.Web_ID, _
                    Me.rblOSCSecurityType.SelectedValue)

                RaiseEvent HeaderSelectedSecurityTypeChange()
            Catch ex As Exception

            End Try
        End Sub
#End Region

#Region " Private Methods "

        Private Function CalculatePercentage( _
                                ByVal aPercentage As Integer) As String
            If aPercentage > 75 Then
                Return "<span class='green'>" & aPercentage & "% Called</span>"
            ElseIf aPercentage <= 75 And aPercentage >= 50 Then
                Return "<span class='orange'>" & aPercentage & "% Called</span>"
            Else
                Return "<span class='red'>" & aPercentage & "% Called</span>"
            End If
        End Function

        Private Sub SetUpStyleSeasToday(
            ByVal aReportType As String)

            'Me.aSTCGuide.Visible = True
            Me.divPromoLogo.Attributes.Add("class", "STCPromo")

            Me.spnTitleSTCIdealProspects.Attributes.Add("class", CStr(IIf(aReportType = "IdealProspects", "active_title", "title")))
            Me.spnTitleSTCProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active_title", "title")))
            Me.spnTitleSTCOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))

            Me.tdTitleSTCIdealProspects.Attributes.Add("class", CStr(IIf(aReportType = "IdealProspects", "active", "headings")))
            Me.tdTitleSTCProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active", "headings")))
            Me.tdTitleSTCOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))

            Select Case aReportType
                Case "IdealProspects"
                    Me.lblReportTitle.Text = "Report Info: Ideal Prospects"
                    Me.lblReportDesc.Text = "<p>Any prospect that has:</p>" & _
                                            "<ul class ='promoLevel1'>" & _
                                                "<li>Joined your 7SEAS&reg; Club since January 2011</li>" & _
                                                "<li>Never booked a cruise</li>" & _
                                                "<li><strong>AND</strong> has done <strong style='text-decoration:underline'>AT LEAST ONE</strong> of the following:" & _
                                                "<ul class ='promoLevel2'>" & _
                                                    "<li>Inquired about at least one of the following cruise lines through the website</li>" & _
                                                    "<ul class='promoLevel3'> " & _
                                                        "<li>Royal Caribbean International</li>" & _
                                                        "<li>Princess Cruises</li>" & _
                                                        "<li>Norwegian Cruise Line</li>" & _
                                                        "<li>Celebrity Cruises</li>" & _
                                                        "<li>Carnival Cruise Lines</li>" & _
                                                        "<li>Holland America Line</li>" & _
                                                    "</ul>" & _
                                                    "<li>Have selected one of the brands above in their 7SEAS profile</li>" & _
                                                "</ul>" & _
                                            "</ul>"
                Case "Prospects"
                    Me.lblReportTitle.Text = "Report Info: Prospects"
                    Me.lblReportDesc.Text = "<p>Any prospect that has:</p>" & _
                                            "<ul class ='promoLevel1'>" & _
                                                "<li>Joined your 7SEAS&reg; Club since June 2012</li>" & _
                                                "<li>Never booked a cruise</li>" & _
                                                "<li>AND subscribed to at least 1+ email marketing pieces</li>" & _
                                                "<li>AND not in the 'Ideal Prospects' list</li>" & _
                                            "</ul>"
                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "<p>These 7SEAS® contacts are not identified in your Seas Today; however, any conversations that you have with other customers or prospects during the promotion can be recorded in the Sales Communication Journal by clicking the ‘Seas Today’ button in your customers’ 7SEAS profile. This will indicate that they have been called and will update your Call List dashboard.</p>"

                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "<p>The SEAS TODAY Call Lists identifies the best prospects to call within your 7SEAS database prior to and during the SEAS TODAY promotion that are most inclined to purchase from you. We also encourage you to call any past customers or contacts outside of this list that you feel would benefit from the promotion.</p>"
            End Select

        End Sub

        Private Sub SetUpStyleWorldExplorer(
                    ByVal aReportType As String)

            'Me.aWEEGuide.Visible = True
            Me.divPromoLogo.Attributes.Add("class", "image")

            Me.spnTitlePremium.Attributes.Add("class", CStr(IIf(aReportType = "Premium", "active_title", "title")))
            Me.spnTitleDeluxe.Attributes.Add("class", CStr(IIf(aReportType = "Deluxe", "active_title", "title")))
            Me.spnTitleLuxuryRiver.Attributes.Add("class", CStr(IIf(aReportType = "LuxuryRiver", "active_title", "title")))
            Me.spnTitleProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active_title", "title")))
            Me.spnTitleOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))

            Me.tdTitlePremium.Attributes.Add("class", CStr(IIf(aReportType = "Premium", "active", "headings")))
            Me.tdTitleDeluxe.Attributes.Add("class", CStr(IIf(aReportType = "Deluxe", "active", "headings")))
            Me.tdTitleLuxuryRiver.Attributes.Add("class", CStr(IIf(aReportType = "LuxuryRiver", "active", "headings")))
            Me.tdTitleProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active", "headings")))
            Me.tdTitleOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))

            Select Case aReportType
                Case "Premium"
                    Me.lblReportTitle.Text = "Report Info: Premium"
                    Me.lblReportDesc.Text = "This call list identifies any 7SEAS Contacts who have purchased from you before.  These contacts include past passengers of any of the cruise lines that fall under the Premium category, or they have been identified through analysis as a customer who has a strong potential to purchase a premium cruise from you."
                Case "Deluxe"
                    Me.lblReportTitle.Text = "Report Info: Deluxe"
                    Me.lblReportDesc.Text = "This call list identifies any 7SEAS Contacts who have purchased from you before.  These contacts include past passengers of any of the cruise lines that fall under the Deluxe category, or they have been identified through analysis as a customer who has a strong potential to purchase a deluxe cruise from you."
                Case "LuxuryRiver"
                    Me.lblReportTitle.Text = "Report Info: Luxury & River"
                    Me.lblReportDesc.Text = "This call list identifies any 7SEAS Contacts who have purchased from you before.  These contacts include past passengers of any of the cruise lines that fall under the Luxury and/or River category, or they have been identified through analysis as a customer who has a strong potential to purchase a luxury or river cruise from you."
                Case "Prospects"
                    Me.lblReportTitle.Text = "Report Info: Prospects"
                    Me.lblReportDesc.Text = "This call list identifies any 7SEAS Contacts who are eligible prospects for World Explorer.   Prospects identified in this list have requested information for Premium, Deluxe, Luxury & River cruise lines via the lead management system or are active subscribers to Europe/Exotic CruiseShipWeekly but have never purchased cruise from us before."
                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "The 7SEAS profiles displayed in this report are contact names that are not identified in your WEE Call Lists but you  have a captured a World Explorer conversation by clicking the 'World Explorer Call' button in these 7SEAS profiles."
                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "The World Explorer Call Lists help you identify the best contacts within your 7SEAS database to talk to prior and during the World Explorer promotion.  These lists are here as a guide, so we encourage you to call contacts outside of this list if you feel they are great prospects for World Explorer campaign.  The World Explorer Guide link listed below will provide tools for World Explorer - including an overview guide and call scripts!"
            End Select

        End Sub

        Private Sub SetUpStyleOneDaySale( _
                        ByVal aReportType As String)

            'Me.aOSCGuide.Visible = True

            Me.divPromoLogo.Attributes.Add("class", "STCPromo")

            Me.spnTitleOSClist1.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active_title", "title")))
            Me.spnTitleOSClist2.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active_title", "title")))
            Me.spnTitleOSClist3.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active_title", "title")))
            Me.spnTitleOSClist4.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))

            Me.tdListOSC1.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active", "headings")))
            Me.tdListOSC2.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active", "headings")))
            Me.tdListOSC3.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active", "headings")))
            Me.tdListOSC4.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))



            Select Case aReportType

                Case "PastCustomers"
                    Me.lblReportTitle.Text = "Report Info: Past Princess Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your Past Princess Customers. They have sailed on a Princess cruise before. The list is made up of 7SEAS® contact members who: <br /><br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are the ‘main’ contact<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with sailing date from March 1st 2012 and onwards<br />"

                Case "IdealCustomers"
                    Me.lblReportTitle.Text = "Report Info: Ideal Princess Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your Ideal Princess Customers who have booked a cruise in the past and who would be a great prospect to book a Princess cruise.  The list is made up of 7SEAS® contact members who:<br /><br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are the ‘main’ contact<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with a  sailing date from March 1st 2012 and onwards<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;And do not appear in list 1<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have done at least one of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have booked a balcony or suit on one of the following cruise lines from 2009 onwards<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Carnival Cruise Lines<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Royal Caribbean<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Norwegian Cruise Line<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Or have booked a cruise in the past with one of the following cruise lines from 2009 onwards<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Holland America Line<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Disney Cruise Line<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Celebrity Cruises<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Or are ticked in the Premium Customer Target Group in their 7SEAS profile<br />"


                Case "Prospects"
                    Me.lblReportTitle.Text = "Report Info: Prospects"
                    Me.lblReportDesc.Text = "This Call List identifies your Princess prospects which are made up of 7SEAS® contact members who have never booked a cruise from you in the past and:<br /><br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are the ‘main’ contact<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have joined 7SEAS in the past 6 months<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Not in List 1 or 2<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;And have done any of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have enquired about Princess Cruises through the consumer website<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Is ticked as Interested in Princess Cruises in CruiseDesk<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;are subscribed to one or the other of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;CruiseShipWeekly Alaska<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;CruiseShipWeekly Europe/Exotics<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;CruiseShipWeekly Caribbean<br />"

                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "These 7SEAS® contacts are not identified in your 1 day sale's Call Lists; however, any conversations that you have with other customers or prospects during the promotion can be recorded in the Sales Communication Journal by clicking the ‘1 day sale’ button in your customers’ 7SEAS profile. This will indicate that they have been called, and will update your activities."
                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "These Call Lists identify the best customers and prospects to talk to within your 7SEAS® Club prior to and during the promotion as they are most likely  to purchase during 1 day sale. We also encourage you to call any contacts outside of these lists that you feel would benefit from the promotion which will be recorded in Additional Calls Made."
            End Select
        End Sub

        'the content of this sub may need to be changed later on
        Private Sub SetUpStyleEEC(ByVal aReportType As String)

            'Me.aEECGuide.Visible = True
            Me.divPromoLogo.Attributes.Add("class", "STCPromo")

            Me.spnTitleEECIdealCustomers.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active_title", "title")))
            Me.spnTitleEECIdealProspects.Attributes.Add("class", CStr(IIf(aReportType = "IdealProspects", "active_title", "title")))
            Me.spnTitleEECOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))
            Me.spnTitleEECPastCustomers.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active_title", "title")))


            Me.tdTitleEECIdealCustomers.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active", "headings")))
            Me.tdTitleEECIdealProspects.Attributes.Add("class", CStr(IIf(aReportType = "IdealProspects", "active", "headings")))
            Me.tdTitleEECOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))
            Me.tdTitleEECPastCustomers.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active", "headings")))

            Select Case aReportType
                Case "IdealCustomers"
                    Me.lblReportTitle.Text = "Report Info: Ideal Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your ideal customers for this promotion as they have sailed with you in the past, are not currently booked for any future cruises and are subscribed to CruiseShipWeekly Europe/Exotic. The list is made up of 7SEAS® contact members who have booked a cruise from you in past and:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have sailed between January 1, 2009 and August 1, 2011<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with a current or future cruise booking<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are subscribed to CruiseShipWeekly Europe/Exotic<br />" & vbCrLf
                Case "PastCustomers"
                    Me.lblReportTitle.Text = "Report Info: Past Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your past customers who are not currently booked for any future cruises. They may not be subscribed to CruiseShipWeekly Europe/Exotic; however, they are likely to book during this promotion as they have sailed in the past.<br />" & vbCrLf & _
                                            "The list is made up of 7SEAS® contact members who have booked a cruise from you in past and:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Sailed between January 1, 2009 and August 1, 2011<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Does not have a CTO on file with a current or future cruise booking<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Does not appear in the list above<br />" & vbCrLf
                Case "IdealProspects"
                    Me.lblReportTitle.Text = "Report Info: Ideal Prospects"
                    Me.lblReportDesc.Text = "This Call List identifies your prospects for this promotion which are made up of 7SEAS® contact members who have never booked a cruise from you in the past and:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have joined the past 2 years<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have done either one or both of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Inquired about Europe through your consumer website<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are subscribed to CruiseShipWeekly Europe/Exotic<br />" & vbCrLf

                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "These 7SEAS contacts are not identified in your Extraordinary Europe Call Lists; however, any conversations that you have with other customers or prospects during the promotion can be recorded in the Sales Communication Journal by clicking the ‘Extraordinary Europe Call’ button in your customers’ 7SEAS® profile. This will indicate that they have been called, and will update your Call List dashboard."
                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "These Call Lists identify the best customers and prospects to talk to within your 7SEAS® Club prior to and during the promotion as they are most likely  to purchase during Extraordinary Europe. We also encourage you to call any contacts outside of these lists that you feel would benefit from the promotion which will be recorded in Additional Calls Made."
            End Select

        End Sub

        Private Sub SetUpStyleEAC(ByVal aReportType As String)

            Me.divPromoLogo.Attributes.Add("class", "EACPromo")

            Me.spnTitleEACEuropeAlaskaCustomers.Attributes.Add("class", CStr(IIf(aReportType = "EuropeAlaskaCustomers", "active_title", "title")))
            Me.spnTitleEACEuropeCustomers.Attributes.Add("class", CStr(IIf(aReportType = "EuropeCustomers", "active_title", "title")))
            Me.spnTitleEACAlaskaCustomers.Attributes.Add("class", CStr(IIf(aReportType = "AlaskaCustomers", "active_title", "title")))
            Me.spnTitleEACProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active_title", "title")))
            Me.spnTitleEACOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))

            Me.tdTitleEACEuropeAlaskaCustomers.Attributes.Add("class", CStr(IIf(aReportType = "EuropeAlaskaCustomers", "active", "headings")))
            Me.tdTitleEACEuropeCustomers.Attributes.Add("class", CStr(IIf(aReportType = "EuropeCustomers", "active", "headings")))
            Me.tdTitleEACAlaskaCustomers.Attributes.Add("class", CStr(IIf(aReportType = "AlaskaCustomers", "active", "headings")))
            Me.tdTitleEACProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active", "headings")))
            Me.tdTitleEACOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))

            Select Case aReportType
                Case "EuropeAlaskaCustomers"
                    Me.lblReportTitle.Text = "Report Info: Ideal Europe and Alaska Customers"
                    Me.lblReportDesc.Text = "This call list identifies your customers who have met the following criteria:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Sailed between January 1, 2010 to December 31, 2012<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;DOES NOT have a CTO on file with a FUTURE cruise already booked<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Subscribed to the 'Exotics & Europe' <strong>AND</strong> 'Alaska' email marketing piece<br />" & vbCrLf
                Case "EuropeCustomers"
                    Me.lblReportTitle.Text = "Report Info: Europe Customers"
                    Me.lblReportDesc.Text = "This call list identifies your customers who have met the following criteria:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Sailed between January 1, 2010 to December 31, 2012<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;DOES NOT have a CTO on file with a FUTURE cruise already booked<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Subscribed to the 'Exotics & Europe' email marketing piece<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Not listed in the 'Ideal Europe and Alaska Customers' list<br />" & vbCrLf
                Case "AlaskaCustomers"
                    Me.lblReportTitle.Text = "Report Info: Alaska Customers"
                    Me.lblReportDesc.Text = "This call list identifies your customers who have met the following criteria:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Sailed between January 1, 2010 to December 31, 2012<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;DOES NOT have a CTO on file with a FUTURE cruise already booked<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Subscribed to the 'Alaska' email marketing piece<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Not listed in the 'Ideal Europe and Alaska Customers' list<br />" & vbCrLf
                Case "Prospects"
                    Me.lblReportTitle.Text = "Report Info: Ideal Prospects"
                    Me.lblReportDesc.Text = "Any prospect that has:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Never booked a cruise<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;AND has done either one or both of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Inquired about Europe OR Alaska through the consumer website<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Subscribed to the 'Europe & Exotics' OR 'Alaska' email marketing piece<br />" & vbCrLf

                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "These 7SEAS® contacts are not identified in your Extraordinary Europe / Awesome Alaska Call Lists; however, any conversations that you have with other customers or prospects during the promotion can be recorded in the Sales Communication Journal by clicking the ‘Extraordinary Europe/Alaska Call’ button in your customers’ 7SEAS profile. This will indicate that they have been called, and will update your Call List dashboard."
                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "These Call Lists identify the best customers and prospects to talk to within your 7SEAS® Club prior to and during the promotion as they are most likely  to purchase during Extraordinary Europe and Awesome Alaska. We also encourage you to call any contacts outside of these lists that you feel would benefit from the promotion which will be recorded in Additional Calls Made."
            End Select

        End Sub

        Private Sub SetUpStyleSSC(ByVal aReportType As String)

            'Me.aSSCGuide.Visible = True
            Me.divPromoLogo.Attributes.Add("class", "STCPromo")


            Me.spnTitleSSCIdealCustomers.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active_title", "title")))
            Me.spnTitleSSCPastCustomers.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active_title", "title")))
            Me.spnTitleSSCProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active_title", "title")))
            Me.spnTitleSSCOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))


            Me.tdTitleSSCIdealCustomers.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active", "headings")))
            Me.tdTitleSSCPastCustomers.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active", "headings")))
            Me.tdTitleSSCProspects.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active", "headings")))
            Me.tdTitleSSCOther.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))



            Select Case aReportType
                Case "FutureCruiseCredit"
                    Me.lblReportTitle.Text = "Report Info: Future Cruise Credit"
                    Me.lblReportDesc.Text = "This Call List identifies your ideal customers for this promotion as they have sailed with Royal Caribbean in the past and are not currently booked for any future cruises. The list is made up of your 7SEAS contact members who have booked a cruise from you in past and:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Contact Type = Main<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Sailed with Royal Caribbean between January 1, 2009 and November 1, 2011<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with a current or future cruise booking<br />" & vbCrLf
                Case "IdealCustomers"
                    Me.lblReportTitle.Text = "Report Info: Ideal Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your ideal customers for this promotion as they have sailed with Royal Caribbean in the past and are not currently booked for any future cruises. <br />" & vbCrLf & _
                                            "The list is made up of your 7SEAS contact members who have booked a cruise from you in past and:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Contact Type = Main<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Sailed with Royal Caribbean between January 1, 2009 and November 1, 2011<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with a current or future cruise booking<br />" & vbCrLf
                Case "PastCustomers"
                    Me.lblReportTitle.Text = "Report Info: Past Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your past contemporary customers who have not booked with Royal Caribbean and who are not currently booked for any future cruises.<br />" & vbCrLf & _
                                            "The list is made up of 7SEAS contact members who have:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Contact Type = Main<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Booked a contemporary cruise in the past (other than Royal Caribbean) between January 1, 2009 and November 1, 2011<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with a current or future cruise booking<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;And do not appear in list 1<br />" & vbCrLf
                Case "Prospects"
                    Me.lblReportTitle.Text = "Report Info: Prospects"
                    Me.lblReportDesc.Text = "This Call List identifies your prospects who have never booked a cruise, are within the Contemporary customer target group and have expressed interest in Royal Caribbean:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Contact Type = Main<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;AND Joined 7SEAS in the past two years<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;AND Never booked a cruise<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have done either <b><u>one or both</u></b> of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Inquired about Royal Caribbean through the consumer website<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are in the Contemporary Customer Target Group<br />" & vbCrLf

                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "These 7SEAS contacts are not identified in your Super Sale Call Lists; however, any conversations that you have with other customers or prospects during the promotion can be recorded in the Sales Communication Journal by clicking the ‘Super Sale Call’ button in your customers’ 7SEAS® profile. This will indicate that they have been called, and will update your Call List dashboard."
                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "These Call Lists identify the best customers and prospects to talk to within your 7SEAS® Club prior to and during the promotion as they are most likely  to purchase during Super Sale. We also encourage you to call any contacts outside of these lists that you feel would benefit from the promotion which will be recorded in Additional Calls Made."
            End Select

        End Sub



        Private Sub SetUpStyleLRC(ByVal aReportType As String)

            'Me.aLRCGuide.Visible = True
            Me.divPromoLogo.Attributes.Add("class", "STCPromo")

            Me.spnTitleLRClist1.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active_title", "title")))
            Me.spnTitleLRClist2.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active_title", "title")))
            Me.spnTitleLRClist3.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active_title", "title")))
            Me.spnTitleLRClist4.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active_title", "title")))

            Me.tdTitleLRCList1.Attributes.Add("class", CStr(IIf(aReportType = "PastCustomers", "active", "headings")))
            Me.tdTitleLRCList2.Attributes.Add("class", CStr(IIf(aReportType = "IdealCustomers", "active", "headings")))
            Me.tdTitleLRCList3.Attributes.Add("class", CStr(IIf(aReportType = "Prospects", "active", "headings")))
            Me.tdTitleLRCList4.Attributes.Add("class", CStr(IIf(aReportType = "Other", "active", "headings")))



            Select Case aReportType

                Case "PastCustomers"
                    Me.lblReportTitle.Text = "Report Info: Past River Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your Past River Customers. They have sailed on a River cruise before and do not have any cruises booked for 2013 and onwards. The list is made up of 7SEAS® contact members who: <br /><br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are the ‘main’ contact<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have sailed with one of the following cruise lines:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;AMA Waterways<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Uniworld Boutique River Cruises<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Viking River Cruises<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Scenic Tours<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Avalon Waterways<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with sailing date from March 1st 2013 and onwards<br />"

                Case "IdealCustomers"
                    Me.lblReportTitle.Text = "Report Info: Ideal River Customers"
                    Me.lblReportDesc.Text = "This Call List identifies your Ideal River Customers who have booked a cruise in the past and who would be a great prospect to book a River cruise.  The list is made up of 7SEAS® contact members who:<br /><br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are the ‘main’ contact<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have booked a cruise in the past <br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Do not have a CTO on file with a  sailing date from March 1st 2013 and onwards<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have done at least one of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Are ticked in the River Customer Target Group in their 7SEAS profile<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have requested information about Azamara Club Cruises or Oceania Cruises through your website<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;And do not appear in list 1<br />"

                Case "Prospects"
                    Me.lblReportTitle.Text = "Report Info: Prospects"
                    Me.lblReportDesc.Text = "This Call List identifies your River prospects which are made up of 7SEAS® contact members who have never booked a cruise from you in the past and:<br /><br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have joined 7SEAS in the past 3 years<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Never booked a cruise<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;And have done at least one of the following:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have inquired about one of the following cruise lines:<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;AMA Waterways<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Uniworld Boutique River Cruises<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Viking River Cruises<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Scenic Tours<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Avalon Waterways<br />" & vbCrLf & _
                                            "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&bull;&nbsp;&nbsp;&nbsp;Have inquired about Europe and/or Russia through your website<br />"

                Case "Other"
                    Me.lblReportTitle.Text = "Report Info: Additional Calls Made"
                    Me.lblReportDesc.Text = "These 7SEAS® contacts are not identified in your Legendary River's Call Lists; however, any conversations that you have with other customers or prospects during the promotion can be recorded in the Sales Communication Journal by clicking the ‘Legendary Rivers’ button in your customers’ 7SEAS profile. This will indicate that they have been called, and will update your activities."
                Case Else
                    Me.lblReportTitle.Text = ""
                    Me.lblReportDesc.Text = "These Call Lists identify the best customers and prospects to talk to within your 7SEAS® Club prior to and during the promotion as they are most likely  to purchase during Super Sale. We also encourage you to call any contacts outside of these lists that you feel would benefit from the promotion which will be recorded in Additional Calls Made."
            End Select

        End Sub

        Private Sub ShowRefreshTime()

            Me.lblLastRefreshTime.Text = "Last Refresh Time = " & Me.GetLastHour(Me.TimerLength)
            Me.lblNextRefreshTime.Text = "Next Refresh Time = " & Me.GetNextHour(Me.TimerLength)
            Me.lblTimeNotification.Text = "Please note that the summary results will refresh every " & _
                                            CStr(IIf(Me.TimerLength = 2, "half-hour", "hour"))

        End Sub

#End Region

#Region " Public Methods "

        Public Sub LoadHeaderSeasToday( _
                            ByVal aReportType As String, _
                            ByVal aSelectedWeb_ID As Integer, _
                            ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "STC"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblSTCSecurityType.SelectedValue = "all"
            Else
                Me.rblSTCSecurityType.SelectedValue = "same"
            End If

            Me.pnlSeasToday.Visible = True

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblSTCSecurityType.Visible = False
            End If

            Me.spnLabelSTC.Style.Value = "display:block"
            'Me.pnlEEC.Visible = False
            'Me.pnlSeasToday.Visible = True
            'Me.rblEECSecurityType.Visible = False
            'Me.rblSSCSecurityType.Visible = False
            'Me.rblSTCSecurityType.Visible = True
            'Me.spnLabelEEC.Style.Value = "display:none"
            'Me.spnLabelSSC.Style.Value = "display:none"
            'Me.spnLabelSTC.Style.Value = "display:block"
            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)

            Me.SetUpStyleSeasToday(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Or
                Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CALL) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.rptSeasToday
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub


        Public Sub LoadHeaderEEC( _
                    ByVal aReportType As String, _
                    ByVal aSelectedWeb_ID As Integer, _
                    ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "EEC"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblEECSecurityType.SelectedValue = "all"
            Else
                Me.rblEECSecurityType.SelectedValue = "same"
            End If

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblEECSecurityType.Visible = False
            End If
            Me.pnlEEC.Visible = True
            Me.pnlSeasToday.Visible = False
            Me.rblEECSecurityType.Visible = True
            Me.rblSTCSecurityType.Visible = False
            Me.rblSSCSecurityType.Visible = False
            Me.spnLabelEEC.Style.Value = "display:block"
            Me.spnLabelSTC.Style.Value = "display:none"
            Me.spnLabelSSC.Style.Value = "display:none"
            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
            Me.SetUpStyleEEC(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Or
                Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CALL) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.EECRepeater
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub


        Public Sub LoadHeaderEAC( _
                   ByVal aReportType As String, _
                   ByVal aSelectedWeb_ID As Integer, _
                   ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "EAC"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblEACSecurityType.SelectedValue = "all"
            Else
                Me.rblEACSecurityType.SelectedValue = "same"
            End If

            'Make the elements visible ( pnlEAC, rblEACSecurityType, spnLabelEAC)
            Me.pnlEAC.Visible = True

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblEACSecurityType.Visible = False
            Else
                Me.rblEACSecurityType.Visible = True
            End If

            Me.spnLabelEAC.Style.Value = "display:block"

            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
            Me.SetUpStyleEAC(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Or
                Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CALL) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.EACRepeater
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub

        Public Sub LoadHeaderSSC( _
                            ByVal aReportType As String, _
                            ByVal aSelectedWeb_ID As Integer, _
                            ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "SSC"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblSSCSecurityType.SelectedValue = "all"
            Else
                Me.rblSSCSecurityType.SelectedValue = "same"
            End If

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblSSCSecurityType.Visible = False
            End If
            Me.pnlSSC.Visible = True
            Me.pnlSeasToday.Visible = False
            Me.pnlEEC.Visible = False
            Me.rblSSCSecurityType.Visible = True
            Me.rblSTCSecurityType.Visible = False
            Me.spnLabelSSC.Style.Value = "display:block"
            Me.spnLabelSTC.Style.Value = "display:none"
            Me.spnLabelEEC.Style.Value = "display:none"
            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
            Me.SetUpStyleSSC(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Or
                Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CALL) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.SSCRepeater
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub




        Public Sub LoadHeaderLRC( _
                            ByVal aReportType As String, _
                            ByVal aSelectedWeb_ID As Integer, _
                            ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "LRC"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblLRCSecurityType.SelectedValue = "all"
            Else
                Me.rblLRCSecurityType.SelectedValue = "same"
            End If

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblLRCSecurityType.Visible = False
            End If
            Me.pnlOneDaySale.Visible = False
            Me.pnlLRC.Visible = True
            Me.pnlSSC.Visible = False
            Me.pnlSeasToday.Visible = False
            Me.pnlEEC.Visible = False

            Me.rblLRCSecurityType.Visible = True
            Me.rblOSCSecurityType.Visible = False
            Me.rblSSCSecurityType.Visible = False
            Me.rblSTCSecurityType.Visible = False

            Me.spnLabelLRC.Style.Value = "display:block"
            Me.spnLabelOSC.Style.Value = "display:none"
            Me.spnLabelSSC.Style.Value = "display:none"
            Me.spnLabelSTC.Style.Value = "display:none"
            Me.spnLabelEEC.Style.Value = "display:none"
            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
            Me.SetUpStyleLRC(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Or
                Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CALL) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.LRCRepeater
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub



        Public Sub LoadHeaderOSC( _
                        ByVal aReportType As String, _
                        ByVal aSelectedWeb_ID As Integer, _
                        ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "OSC"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblOSCSecurityType.SelectedValue = "all"
            Else
                Me.rblOSCSecurityType.SelectedValue = "same"
            End If

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblOSCSecurityType.Visible = False
            End If
            Me.pnlOneDaySale.Visible = True
            Me.pnlLRC.Visible = False
            Me.pnlSSC.Visible = False
            Me.pnlSeasToday.Visible = False
            Me.pnlEEC.Visible = False

            Me.rblOSCSecurityType.Visible = True
            Me.rblLRCSecurityType.Visible = False
            Me.rblSSCSecurityType.Visible = False
            Me.rblSTCSecurityType.Visible = False

            Me.spnLabelOSC.Style.Value = "display:block"
            Me.spnLabelLRC.Style.Value = "display:none"
            Me.spnLabelSSC.Style.Value = "display:none"
            Me.spnLabelSTC.Style.Value = "display:none"
            Me.spnLabelEEC.Style.Value = "display:none"
            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
            Me.SetUpStyleOneDaySale(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Or
                Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CALL) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.OSCRepeater
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub



        Public Sub LoadHeaderWorldExplorer( _
                            ByVal aReportType As String, _
                            ByVal aSelectedWeb_ID As Integer, _
                            ByVal aSecurityType As String)

            Dim mySecurityType As AD.UI.Enums.SelectedSecurityType = AD.UI.Enums.SelectedSecurityType.Same
            Dim myDT As DataTable
            Dim myDT2 As DataTable
            Dim myDT3 As DataTable
            Dim myDT4 As DataTable

            Me.PromotionType = "WWE"
            If aSecurityType.ToLower = "all" Then
                mySecurityType = AD.UI.Enums.SelectedSecurityType.All
                Me.rblSecurityType.SelectedValue = "all"
            Else
                Me.rblSecurityType.SelectedValue = "same"
            End If

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                Me.rblSecurityType.Visible = False
            End If

            myDT = SS.BusinessLogic.Request.ReadPromotionHeader(aSelectedWeb_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)

            Me.SetUpStyleWorldExplorer(aReportType)
            Me.ShowRefreshTime()
            Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
            Me.ReportType = aReportType
            Me.ReportTypeLink = aReportType

            If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
            ElseIf Me.Authenticate.Web_ID <> aSelectedWeb_ID Then ' Merge the center and consultant list
                myDT2 = SS.BusinessLogic.Request.ReadPromotionHeader(Me.Authenticate.Web_ID, Me.Authenticate.Web_ID, mySecurityType, Me.PromotionType)
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 0"
                myDT2.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT3 = myDT.DefaultView.ToTable.Copy
                myDT4 = myDT2.DefaultView.ToTable.Copy
                myDT3.Merge(myDT4)
                myDT = myDT3
            End If

            If myDT.Rows.Count > 1000 Then
                myDT.DefaultView.RowFilter = "IsUserOrCenter = 1"
                myDT2 = myDT.DefaultView.ToTable
                If myDT2.Rows.Count > 0 Then
                    myDT2.Rows(0)("FullName") = "CORPORATE"
                End If
                myDT = myDT2
            End If

            If myDT.DefaultView.Count > 0 Then
                With Me.rptWorldExplorer
                    .DataSource = myDT.DefaultView
                    .DataBind()
                End With
            End If

        End Sub


        'Public Sub LoadHeaderOneDaySale( _
        '            ByVal aReportType As String, _
        '            ByVal aSelectedWeb_ID As Integer, _
        '            ByVal aCenter_ID As Integer, _
        '            ByVal aUser_ID As Integer, _
        '            ByVal aUserOrCenter As String)

        '    Dim myDT As DataTable

        '    Me.PromotionType = "ODS"
        '    If aReportType = "CCD" And Not Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
        '        myDT = SS.BusinessLogic.Request.ReadPromotionHeaderOneDaySale(aCenter_ID, 0, aSelectedWeb_ID, aUserOrCenter)
        '    Else
        '        myDT = SS.BusinessLogic.Request.ReadPromotionHeaderOneDaySale(aCenter_ID, aUser_ID, aSelectedWeb_ID, aUserOrCenter)
        '    End If

        '    Me.SetUpStyleOneDaySale(aReportType)

        '    If myDT.Rows.Count > 0 Then
        '        'myDT.DefaultView.RowFilter = "isOWNR <> 1"
        '        Me.rptHeaderOneDaySale.DataSource = myDT
        '        If Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
        '            myDT.DefaultView.RowFilter = "IsUserOrCenter = 'User'"
        '        End If
        '        If Not Me.Authenticate.IsInRole(CS.CSEnums.Enums.Roles.CSLT) Then
        '            myDT.DefaultView.RowFilter = "IsUserOrCenter = '' or IsUserOrCenter = 'User' or FullName = 'Heading'"
        '        End If
        '        Me.rptHeaderOneDaySale.DataBind()
        '    End If

        '    Me.tdTitleIPC.Visible = Not Me.Authenticate.Country.ToLower = "us"
        '    Me.tdIPCCallScript.Visible = Me.tdTitleIPC.Visible

        '    Me.ShowRefreshTime()

        '    If aUserOrCenter = "User" Then
        '        Me.Center_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aCenter_ID)
        '        Me.User_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aUser_ID)
        '        Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(aSelectedWeb_ID)
        '        Me.ReportTypeLink = aReportType
        '    End If

        'End Sub


        Public Function ShowPercent( _
                            ByVal aCallCount As Object, _
                            ByVal aCount As Object) As String
            Dim myCallCount As Decimal = CS.CSDataHelpers.Helpers.ConvertDecimalFromNull(aCallCount)
            Dim myCount As Decimal = CS.CSDataHelpers.Helpers.ConvertDecimalFromNull(aCount)
            Dim myRetVal As String = Me.CalculatePercentage(0)

            If myCallCount > 0 And myCount > 0 Then
                myRetVal = Me.CalculatePercentage(CInt((myCallCount / myCount) * 100))
            End If

            Return myRetVal
        End Function

        Public Function LinkReport( _
                            ByVal aWebID As Object, _
                            ByVal aCallCount As Object, _
                            ByVal aCount As Object, _
                            ByVal aReportType As Object, _
                            ByVal aCenterID As Object, _
                            ByVal aUserID As Object, _
                            ByVal aIsUserOrCenter As Object, _
                                  Optional ByVal aFullName As Object = "") As String

            Dim myWebID As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aWebID)
            Dim myCallCount As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aCallCount)
            Dim myCount As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aCount)
            Dim myReportType As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aReportType)
            Dim myCenterID As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aCenterID)
            Dim myUserID As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aUserID)
            Dim myUserOrCenter As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aIsUserOrCenter)
            Dim myFullName As String = CS.CSDataHelpers.Helpers.ConvertStrFromNull(aFullName)

            Dim myCallCountText As String = CStr(IIf(myCallCount <> myCount, myCallCount & "/" & myCount, myCount))
            Dim myLinkSecurityType As String = "all"

            If myWebID = Me.Authenticate.Web_ID.ToString AndAlso Not myFullName = "Total" Then
                myLinkSecurityType = "same"
            End If

            If myUserOrCenter = "User" Then
                Me.Center_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(myCenterID)
                Me.User_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(myUserID)
                Me.Web_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(myWebID)
                Me.ReportTypeLink = myReportType
                Me.UserCount += 1
            End If

            If myUserOrCenter = "Center" Then
                Me.CenterHB_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(myCenterID)
                Me.UserHB_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(myUserID)
                Me.WebHB_ID = CS.CSDataHelpers.Helpers.ConvertIntFromString(myWebID)
                Me.ReportTypeLinkHB = myReportType
            End If

            If Me.ReportType = "CCD" Then
                If myUserOrCenter = "Center" Then
                    Return "<a href=""#"">" & myCallCountText & "</a>"
                Else
                    Return "<a href=""" & GetRootName() & "/Report/PromotionReport.aspx?ReportType=" _
                        & myReportType & "&selectedWeb_ID=" & myWebID & "&centerID=" & myCenterID & _
                        "&userID=" & myUserID & "&UserOrCenter=" & myUserOrCenter & """>" & myCallCountText & "</a>"
                End If
            Else
                If myUserOrCenter = "Center" Then
                    If Me.UserCount <= 0 Then
                        Return "<a href=""" & GetRootName() & "/Report/PromotionReport.aspx?ReportType=" _
                            & myReportType & "&selectedWeb_ID=" & Me.WebHB_ID & "&centerID=" & Me.CenterHB_ID & _
                            "&userID=" & Me.UserHB_ID & "&UserOrCenter=" & myUserOrCenter & "&selectedSecurityType=all" & """>" & myCallCountText & "</a>"
                    Else
                        Return "<a href=""" & GetRootName() & "/Report/PromotionReport.aspx?ReportType=" _
                            & myReportType & "&selectedWeb_ID=" & Me.Web_ID & "&centerID=" & Me.Center_ID & _
                            "&userID=" & Me.User_ID & "&UserOrCenter=" & myUserOrCenter & "&selectedSecurityType=all" & """>" & myCallCountText & "</a>"
                    End If
                Else
                    Return "<a href=""" & GetRootName() & "/Report/PromotionReport.aspx?ReportType=" _
                        & myReportType & "&selectedWeb_ID=" & myWebID & "&centerID=" & myCenterID & _
                        "&userID=" & myUserID & "&UserOrCenter=" & myUserOrCenter &
                        "&selectedSecurityType=" & myLinkSecurityType & "&promotype=" & Me.PromotionType &
                        """ > " & myCallCountText & "</a>"
                End If
            End If

        End Function

        Public Function LinkHeaderReport(ByVal reportType As String) As String
            Return GetRootName() & "/Report/PromotionReport.aspx?ReportType=" & reportType & _
                    "&selectedWeb_ID=" & CStr(IIf(Me.Web_ID = 0, Me.WebHB_ID, Me.Web_ID)) & _
                    "&centerID=" & CStr(IIf(Me.Center_ID = 0, Me.CenterHB_ID, Me.Center_ID)) & _
                    "&userID=" & CStr(IIf(Me.User_ID = 0, Me.UserHB_ID, Me.User_ID)) & "&UserOrCenter=User" &
                    "&promotype=" & Me.PromotionType & "&selectedSecurityType=" & Me.SelectedSecurityType
        End Function


        Public Function GetRootName() As String
            Return CS.CSUI.ConfigInfo.RootName
        End Function

        Public Function GetCallListSupportKitFileName() As String
            Return CS.CSUI.ConfigInfo.CallListSupportKitFileName
        End Function

        Public Function GetLastHour(ByVal aWholeOrHalf As Integer) As String
            Dim Hour As Double = DateTime.Now.Hour
            Dim Minute As Integer = DateTime.Now.Minute
            Dim AMorPM As String = CStr(IIf(Now.Hour > 11, "PM", "AM"))

            If Hour > 12 Then
                Hour = Hour - 12
            End If

            If aWholeOrHalf = 2 Then 'Half hour
                If Minute > 30 Then
                    Return Hour.ToString & ":" & "30" & ":" & "00 " & AMorPM
                Else
                    'Hour = Hour - 1
                    Return Hour.ToString & ":" & "00" & ":" & "00 " & AMorPM
                End If
            Else 'one hour
                Return Hour.ToString & ":" & "00" & ":" & "00 " & AMorPM
            End If
        End Function

        Public Function GetNextHour(ByVal aWholeOrHalf As Integer) As String
            Dim Hour As Double = DateTime.Now.Hour + 1
            Dim minute As Integer = DateTime.Now.Minute
            Dim AMorPM As String = CStr(IIf(Now.Hour + 1 > 12, "PM", "AM"))

            If Hour > 12 Then
                Hour = Hour - 12
            End If

            If aWholeOrHalf = 2 Then 'Half hour
                If minute > 30 Then
                    Return Hour.ToString & ":" & "00" & ":" & "00 " & AMorPM
                Else
                    Hour = Hour - 1
                    Return Hour.ToString & ":" & "30" & ":" & "00 " & AMorPM
                End If
            Else 'one hour
                Return Hour.ToString & ":" & "00" & ":" & "00 " & AMorPM
            End If
        End Function

        Public Function GetDefaultReportType(ByVal pomoType As String) As String
            Select Case pomoType
                Case "EAC"
                    Return DefaultReportTypeEAC
                Case "STC"
                    Return DefaultReportTypeSTC
                Case Else
                    Return DefaultReportTypeOthers
            End Select
        End Function

#End Region


    End Class

End Namespace
