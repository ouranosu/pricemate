import 'package:flutter/material.dart';

class LegalSection {
  const LegalSection({required this.heading, required this.body});
  final String heading;
  final String body;
}

class LegalView extends StatelessWidget {
  const LegalView({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                '最終更新日: $lastUpdated',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final section = sections[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.heading,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(section.body, style: textTheme.bodyMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}

const termsOfService = [
  LegalSection(
    heading: '第1条（適用）',
    body:
        '本利用規約（以下「本規約」）は、okstore（以下「当社」）が提供するスマートフォンアプリ「PriceMate」（以下「本サービス」）の利用条件を定めるものです。ユーザーの皆さまには、本規約に従って本サービスをご利用いただきます。',
  ),
  LegalSection(
    heading: '第2条（利用登録）',
    body:
        '本サービスの利用を希望する方は、本規約に同意のうえ、当社の定める方法により利用登録を申請してください。当社が登録を承認した時点で、利用登録が完了するものとします。当社は、以下の場合に利用登録の申請を承認しないことがあります。\n\n・登録申請に虚偽の事項を届け出た場合\n・本規約に違反したことがある者からの申請である場合\n・その他、当社が利用登録を相当でないと判断した場合',
  ),
  LegalSection(
    heading: '第3条（禁止事項）',
    body:
        'ユーザーは、本サービスの利用にあたり、以下の行為をしてはなりません。\n\n・法令または公序良俗に違反する行為\n・犯罪行為に関連する行為\n・当社または第三者の知的財産権、肖像権、プライバシー等を侵害する行為\n・当社または第三者のサーバーやネットワークの機能を破壊・妨害する行為\n・本サービスの運営を妨害するおそれのある行為\n・他のユーザーに関する個人情報等を収集または蓄積する行為\n・不正アクセスをし、またはこれを試みる行為\n・その他、当社が不適切と判断する行為',
  ),
  LegalSection(
    heading: '第4条（本サービスの提供の停止等）',
    body:
        '当社は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本サービスの全部または一部の提供を停止または中断することができるものとします。\n\n・本サービスにかかるコンピュータシステムの保守点検または更新を行う場合\n・地震、落雷、火災、停電または天災などの不可抗力により、本サービスの提供が困難となった場合\n・コンピュータまたは通信回線等が事故により停止した場合\n・その他、当社が本サービスの提供が困難と判断した場合',
  ),
  LegalSection(
    heading: '第5条（免責事項）',
    body:
        '当社の債務不履行責任は、当社の故意または重過失によらない場合には免責されるものとします。本サービスに関して、ユーザーと他のユーザーまたは第三者との間において生じた取引、連絡または紛争等については、当社は一切責任を負いません。',
  ),
  LegalSection(
    heading: '第6条（利用規約の変更）',
    body:
        '当社は必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。なお、本規約の変更後、本サービスの利用を開始した場合には、当該ユーザーは変更後の規約に同意したものとみなします。',
  ),
  LegalSection(
    heading: '第7条（準拠法・裁判管轄）',
    body:
        '本規約の解釈にあたっては、日本法を準拠法とします。本サービスに関して紛争が生じた場合には、当社の本店所在地を管轄する裁判所を専属的合意管轄とします。',
  ),
];

const privacyPolicy = [
  LegalSection(
    heading: '収集する情報',
    body:
        '当社は、本サービスの提供にあたり、以下の情報を収集することがあります。\n\n・氏名、メールアドレス等の登録情報\n・本サービスの利用に関するログ情報（アクセス日時、使用機能など）\n・デバイス情報（機種名、OSバージョンなど）\n・ユーザーが入力した商品情報・価格情報・購入記録',
  ),
  LegalSection(
    heading: '情報の利用目的',
    body:
        '収集した情報は、以下の目的のために利用します。\n\n・本サービスの提供・運営・改善\n・ユーザーからのお問い合わせへの対応\n・利用規約に違反するユーザーの特定および利用停止\n・本サービスに関するお知らせの送信\n・その他、本サービスの運営上必要な業務',
  ),
  LegalSection(
    heading: '第三者への情報提供',
    body:
        '当社は、以下の場合を除き、個人情報を第三者に提供することはありません。\n\n・ユーザーの同意がある場合\n・法令に基づき開示が必要な場合\n・人の生命、身体または財産の保護のために必要がある場合\n・国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合',
  ),
  LegalSection(
    heading: 'データの保管と保護',
    body:
        '当社は、収集した個人情報をGoogle Firebaseのサービスを通じて保管します。不正アクセス・紛失・破損・改ざんなどのリスクに対して、適切なセキュリティ対策を講じています。ただし、インターネット上での完全な安全性を保証することはできません。',
  ),
  LegalSection(
    heading: 'Cookieについて',
    body:
        '本サービスでは、サービスの向上を目的として、ユーザーの利用状況を把握するための情報収集ツールを使用する場合があります。これらはサービス改善にのみ使用し、個人を特定する目的では使用しません。',
  ),
  LegalSection(
    heading: 'ユーザーの権利',
    body:
        'ユーザーは、当社が保有する自己の個人情報について、開示・訂正・削除・利用停止を請求することができます。お問い合わせは、設定画面に記載のメールアドレスまでご連絡ください。',
  ),
  LegalSection(
    heading: 'プライバシーポリシーの変更',
    body:
        '当社は、必要に応じて本プライバシーポリシーを改定することがあります。重要な変更がある場合は、アプリ内またはその他適切な方法でお知らせします。変更後も本サービスを継続して利用された場合は、改定後のポリシーに同意したものとみなします。',
  ),
  LegalSection(
    heading: 'お問い合わせ',
    body:
        '個人情報の取り扱いに関するお問い合わせは、以下までご連絡ください。\n\nokstore\nメール: info@okstore.website',
  ),
];
