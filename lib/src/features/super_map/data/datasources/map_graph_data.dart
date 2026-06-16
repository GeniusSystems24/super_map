// ============================================================
// features/super_map/data/datasources/map_graph_data.dart
// ------------------------------------------------------------
// The bundled sample graphs — a 1:1 port of the React `GL_MAP_SEEDS`. Five
// diagrams that share one engine: a cash-flow map (income → entity → outflows),
// a radial strategy mind-map, a purchase-approval workflow, the accounting
// cycle, and an order-to-cash pipeline. World coordinates are abstract; the
// engine fits them to the viewport on load.
// ============================================================

import '../../domain/entities/map_graph.dart';
import '../../domain/entities/map_node.dart';

/// Static sample diagrams. Never instantiated.
abstract final class MapGraphData {
  // ── 1 · Cash-flow (income → entity → outflows) ──
  static const MapGraph cashFlow = MapGraph(
    id: 'flow',
    title: 'Cash-flow map',
    ar: 'خريطة التدفّق النقدي',
    subtitle:
        'How money moves through the entity — income channels roll into the operating entity, which settles its payables and retains the rest.',
    legend: [MapNodeKind.income, MapNodeKind.hub, MapNodeKind.expense, MapNodeKind.equity],
    nodes: [
      MapNode(id: 'retail', x: 120, y: 80, label: 'Retail Sales', ar: 'مبيعات التجزئة', kind: MapNodeKind.income, sub: 'Channel'),
      MapNode(id: 'wholesale', x: 120, y: 220, label: 'Wholesale', ar: 'مبيعات الجملة', kind: MapNodeKind.income, sub: 'Channel'),
      MapNode(id: 'exports', x: 120, y: 360, label: 'GCC Exports', ar: 'صادرات الخليج', kind: MapNodeKind.income, sub: 'Channel'),
      MapNode(id: 'services', x: 120, y: 500, label: 'Service Revenue', ar: 'إيرادات الخدمات', kind: MapNodeKind.income, sub: 'Channel'),
      MapNode(id: 'company', x: 470, y: 290, label: 'GeniusLink Co.', ar: 'شركة جينيس لينك', kind: MapNodeKind.hub, sub: 'Operating entity'),
      MapNode(id: 'suppliers', x: 840, y: 70, label: 'Suppliers', ar: 'الموردون', kind: MapNodeKind.expense, sub: 'Payable'),
      MapNode(id: 'payroll', x: 840, y: 195, label: 'Payroll', ar: 'الرواتب', kind: MapNodeKind.expense, sub: 'Payable'),
      MapNode(id: 'tax', x: 840, y: 320, label: 'VAT & Zakat', ar: 'الضريبة والزكاة', kind: MapNodeKind.expense, sub: 'Payable'),
      MapNode(id: 'opex', x: 840, y: 445, label: 'Operating Exp.', ar: 'مصروفات تشغيل', kind: MapNodeKind.expense, sub: 'Payable'),
      MapNode(id: 'retained', x: 840, y: 575, label: 'Retained Earnings', ar: 'أرباح محتجزة', kind: MapNodeKind.equity, sub: 'Equity'),
    ],
    edges: [
      MapEdge(id: 'f1', from: 'retail', to: 'company', value: 642000),
      MapEdge(id: 'f2', from: 'wholesale', to: 'company', value: 388000),
      MapEdge(id: 'f3', from: 'exports', to: 'company', value: 214000),
      MapEdge(id: 'f4', from: 'services', to: 'company', value: 96000),
      MapEdge(id: 'f5', from: 'company', to: 'suppliers', value: 318000),
      MapEdge(id: 'f6', from: 'company', to: 'payroll', value: 330000),
      MapEdge(id: 'f7', from: 'company', to: 'tax', value: 56000),
      MapEdge(id: 'f8', from: 'company', to: 'opex', value: 144000),
      MapEdge(id: 'f9', from: 'company', to: 'retained', value: 230000),
    ],
  );

  // ── 2 · Mind-map (radial topic) ──
  static const MapGraph mindMap = MapGraph(
    id: 'mind',
    title: 'Strategy mind-map',
    ar: 'خريطة ذهنية',
    subtitle:
        'A radial idea graph — one central topic branches into themes and ideas. The same engine, a different value type.',
    legend: [MapNodeKind.topic, MapNodeKind.branch, MapNodeKind.leaf],
    nodes: [
      MapNode(id: 'core', x: 470, y: 300, label: 'Q3 Product Strategy', ar: 'استراتيجية المنتج', kind: MapNodeKind.topic),
      MapNode(id: 'growth', x: 175, y: 120, label: 'Growth', kind: MapNodeKind.branch),
      MapNode(id: 'retention', x: 770, y: 120, label: 'Retention', kind: MapNodeKind.branch),
      MapNode(id: 'platform', x: 175, y: 480, label: 'Platform', kind: MapNodeKind.branch),
      MapNode(id: 'brand', x: 770, y: 480, label: 'Brand', kind: MapNodeKind.branch),
      MapNode(id: 'g1', x: 60, y: 40, label: 'Referral loop', kind: MapNodeKind.leaf),
      MapNode(id: 'g2', x: 250, y: 20, label: 'Paid channels', kind: MapNodeKind.leaf),
      MapNode(id: 'r1', x: 880, y: 40, label: 'Onboarding', kind: MapNodeKind.leaf),
      MapNode(id: 'r2', x: 690, y: 18, label: 'Lifecycle email', kind: MapNodeKind.leaf),
      MapNode(id: 'p1', x: 60, y: 560, label: 'API v2', kind: MapNodeKind.leaf),
      MapNode(id: 'p2', x: 250, y: 585, label: 'SSO & SAML', kind: MapNodeKind.leaf),
      MapNode(id: 'b1', x: 880, y: 560, label: 'Rebrand', kind: MapNodeKind.leaf),
      MapNode(id: 'b2', x: 690, y: 585, label: 'Field events', kind: MapNodeKind.leaf),
    ],
    edges: [
      MapEdge(id: 'm1', from: 'core', to: 'growth'),
      MapEdge(id: 'm2', from: 'core', to: 'retention'),
      MapEdge(id: 'm3', from: 'core', to: 'platform'),
      MapEdge(id: 'm4', from: 'core', to: 'brand'),
      MapEdge(id: 'm5', from: 'growth', to: 'g1'),
      MapEdge(id: 'm6', from: 'growth', to: 'g2'),
      MapEdge(id: 'm7', from: 'retention', to: 'r1'),
      MapEdge(id: 'm8', from: 'retention', to: 'r2'),
      MapEdge(id: 'm9', from: 'platform', to: 'p1'),
      MapEdge(id: 'm10', from: 'platform', to: 'p2'),
      MapEdge(id: 'm11', from: 'brand', to: 'b1'),
      MapEdge(id: 'm12', from: 'brand', to: 'b2'),
    ],
  );

  // ── 3 · Administrative — purchase-approval workflow ──
  static const MapGraph approval = MapGraph(
    id: 'admin',
    title: 'Approval workflow',
    ar: 'سير الاعتماد الإداري',
    subtitle:
        'A purchase request routed through the org: department, budget check and finance converge on the CEO before a PO is issued.',
    legend: [MapNodeKind.process, MapNodeKind.role, MapNodeKind.approval, MapNodeKind.document],
    nodes: [
      MapNode(id: 'req', x: 110, y: 300, label: 'Purchase Request', ar: 'طلب شراء', kind: MapNodeKind.process, sub: 'Initiated'),
      MapNode(id: 'mgr', x: 360, y: 300, label: 'Dept. Manager', ar: 'مدير الإدارة', kind: MapNodeKind.role, sub: 'Reviewer'),
      MapNode(id: 'budget', x: 610, y: 150, label: 'Budget Check', ar: 'فحص الميزانية', kind: MapNodeKind.approval, sub: 'Control'),
      MapNode(id: 'finance', x: 610, y: 450, label: 'Finance Review', ar: 'مراجعة مالية', kind: MapNodeKind.role, sub: 'Reviewer'),
      MapNode(id: 'ceo', x: 860, y: 300, label: 'CEO Approval', ar: 'اعتماد الرئيس', kind: MapNodeKind.approval, sub: 'Sign-off'),
      MapNode(id: 'po', x: 1110, y: 300, label: 'Issue PO', ar: 'إصدار أمر شراء', kind: MapNodeKind.document, sub: 'Output'),
    ],
    edges: [
      MapEdge(id: 'a1', from: 'req', to: 'mgr'),
      MapEdge(id: 'a2', from: 'mgr', to: 'budget'),
      MapEdge(id: 'a3', from: 'mgr', to: 'finance'),
      MapEdge(id: 'a4', from: 'budget', to: 'ceo'),
      MapEdge(id: 'a5', from: 'finance', to: 'ceo'),
      MapEdge(id: 'a6', from: 'ceo', to: 'po'),
    ],
  );

  // ── 4 · Accounting — the accounting cycle ──
  static const MapGraph accountingCycle = MapGraph(
    id: 'acct',
    title: 'Accounting cycle',
    ar: 'الدورة المحاسبية',
    subtitle:
        'From a source document to the financial statements: journalise, post to the ledger, balance, adjust, then report.',
    legend: [MapNodeKind.document, MapNodeKind.process, MapNodeKind.account, MapNodeKind.statement],
    nodes: [
      MapNode(id: 'doc', x: 110, y: 300, label: 'Source Document', ar: 'مستند أصلي', kind: MapNodeKind.document, sub: 'Evidence'),
      MapNode(id: 'journal', x: 350, y: 300, label: 'Journal Entry', ar: 'قيد يومية', kind: MapNodeKind.process, sub: 'Record'),
      MapNode(id: 'ledger', x: 590, y: 300, label: 'General Ledger', ar: 'الأستاذ العام', kind: MapNodeKind.account, sub: 'Post'),
      MapNode(id: 'tb', x: 830, y: 300, label: 'Trial Balance', ar: 'ميزان المراجعة', kind: MapNodeKind.process, sub: 'Verify'),
      MapNode(id: 'adj', x: 830, y: 110, label: 'Adjustments', ar: 'تسويات جردية', kind: MapNodeKind.process, sub: 'Accrue'),
      MapNode(id: 'is', x: 1080, y: 200, label: 'Income Statement', ar: 'قائمة الدخل', kind: MapNodeKind.statement, sub: 'Report'),
      MapNode(id: 'bs', x: 1080, y: 400, label: 'Balance Sheet', ar: 'المركز المالي', kind: MapNodeKind.statement, sub: 'Report'),
    ],
    edges: [
      MapEdge(id: 'c1', from: 'doc', to: 'journal'),
      MapEdge(id: 'c2', from: 'journal', to: 'ledger'),
      MapEdge(id: 'c3', from: 'ledger', to: 'tb'),
      MapEdge(id: 'c4', from: 'adj', to: 'tb'),
      MapEdge(id: 'c5', from: 'tb', to: 'is'),
      MapEdge(id: 'c6', from: 'tb', to: 'bs'),
    ],
  );

  // ── 5 · Commercial — order to cash ──
  static const MapGraph orderToCash = MapGraph(
    id: 'commerce',
    title: 'Order to cash',
    ar: 'من الطلب إلى التحصيل',
    subtitle:
        'The commercial pipeline: a customer quotation becomes a sales order, is fulfilled and invoiced, and closes on payment.',
    legend: [MapNodeKind.party, MapNodeKind.document, MapNodeKind.process, MapNodeKind.payment],
    nodes: [
      MapNode(id: 'customer', x: 110, y: 300, label: 'Customer', ar: 'العميل', kind: MapNodeKind.party, sub: 'Account'),
      MapNode(id: 'quote', x: 350, y: 300, label: 'Quotation', ar: 'عرض سعر', kind: MapNodeKind.document, sub: 'Offer'),
      MapNode(id: 'order', x: 590, y: 300, label: 'Sales Order', ar: 'أمر بيع', kind: MapNodeKind.process, sub: 'Confirmed'),
      MapNode(id: 'fulfil', x: 590, y: 110, label: 'Fulfilment', ar: 'التجهيز', kind: MapNodeKind.process, sub: 'Warehouse'),
      MapNode(id: 'invoice', x: 830, y: 300, label: 'Invoice', ar: 'فاتورة', kind: MapNodeKind.document, sub: 'Billed'),
      MapNode(id: 'payment', x: 1080, y: 300, label: 'Payment', ar: 'تحصيل', kind: MapNodeKind.payment, sub: 'Settled', value: 184000),
    ],
    edges: [
      MapEdge(id: 'o1', from: 'customer', to: 'quote'),
      MapEdge(id: 'o2', from: 'quote', to: 'order'),
      MapEdge(id: 'o3', from: 'order', to: 'fulfil'),
      MapEdge(id: 'o4', from: 'fulfil', to: 'invoice'),
      MapEdge(id: 'o5', from: 'order', to: 'invoice'),
      MapEdge(id: 'o6', from: 'invoice', to: 'payment', value: 184000),
    ],
  );

  /// All sample graphs in showcase order.
  static const List<MapGraph> all = [
    cashFlow,
    mindMap,
    approval,
    accountingCycle,
    orderToCash,
  ];
}
