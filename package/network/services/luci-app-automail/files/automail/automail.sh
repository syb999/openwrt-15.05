#!/bin/sh
#我是Auto Mail Sender发送邮件脚本,请修改我来发送具体邮件信息
#收件人邮箱
target=$(uci get automail.@automail[0].recipient)

#默认发送测试邮件内容，请自行修改
echo -e "邮件发送时间:$(date +%Y-%m-%d\ %H:%M)\n你好，我是一封测试邮件！" | mutt -s "来自AutoMail的邮件" -- $target

rm /root/sent >/dev/null 2>&1

