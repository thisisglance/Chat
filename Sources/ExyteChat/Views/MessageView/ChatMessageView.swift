//
//  ChatMessageView.swift
//  
//
//  Created by Alisa Mylnikova on 20.03.2023.
//

import SwiftUI

struct ChatMessageView<MessageContent: View>: View {

    typealias MessageBuilderClosure = (MessageType, PositionInUserGroup, PositionInCommentsGroup, PositionInCommentsGroup, @escaping () -> Void, @escaping (MessageMenuAction) -> Void, @escaping (AttachmentType) -> Void) -> MessageContent?

    @ObservedObject var viewModel: ChatViewModel

    var messageBuilder: MessageBuilderClosure?

    let row: MessageRow
    let chatType: ChatType
    let avatarSize: CGFloat
    let tapAvatarClosure: ChatView.TapAvatarClosure?
    let messageStyler: (String) -> AttributedString
    let shouldShowLinkPreview: (URL) -> Bool
    let isDisplayingMessageMenu: Bool
    let showMessageTimeView: Bool
    let messageLinkPreviewLimit: Int
    let messageFont: UIFont

    var body: some View {
        Group {
            if let messageBuilder = messageBuilder {
                let customView = messageBuilder(
                    row.message,
                    row.positionInUserGroup,
                    row.positionInMessagesSection,
                    row.commentsPosition,
                    { viewModel.messageMenuRow = row },
                    viewModel.messageMenuAction()) { attachment in
                        self.viewModel.presentAttachmentFullScreen(attachment)
                    }
                
                if let customView = customView {
                    customView
                } else {
                    defaultMessageView
                }
            } else {
                defaultMessageView
            }
        }
        .id(row.message.id)
    }
}

private var defaultMessageView: some View {
    MessageView(
        viewModel: viewModel,
        message: row.message,
        positionInUserGroup: row.positionInUserGroup,
        positionInMessagesSection: row.positionInMessagesSection,
        chatType: chatType,
        avatarSize: avatarSize,
        tapAvatarClosure: tapAvatarClosure,
        messageStyler: messageStyler,
        shouldShowLinkPreview: shouldShowLinkPreview,
        isDisplayingMessageMenu: isDisplayingMessageMenu,
        showMessageTimeView: showMessageTimeView,
        messageLinkPreviewLimit: messageLinkPreviewLimit,
        font: messageFont)
}
