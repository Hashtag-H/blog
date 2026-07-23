using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;

namespace LocalBlogManager
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    internal sealed class PostInfo
    {
        public string FilePath;
        public string FileName;
        public string Slug;
        public string Title;
        public string Date;
        public string Updated;
        public string Categories;
        public string Tags;
        public string Description;
        public DateTime Modified;
    }

    internal static class Ui
    {
        public static readonly Color Page = Color.FromArgb(239, 241, 236);
        public static readonly Color Card = Color.FromArgb(255, 255, 252);
        public static readonly Color Ink = Color.FromArgb(32, 36, 31);
        public static readonly Color Muted = Color.FromArgb(99, 105, 96);
        public static readonly Color Border = Color.FromArgb(219, 224, 214);
        public static readonly Color Green = Color.FromArgb(72, 119, 91);
        public static readonly Color GreenHover = Color.FromArgb(61, 104, 79);
        public static readonly Color Wheat = Color.FromArgb(185, 137, 65);
        public static readonly Color WheatHover = Color.FromArgb(162, 116, 50);
        public static readonly Color Blue = Color.FromArgb(66, 104, 141);
        public static readonly Color BlueHover = Color.FromArgb(53, 87, 120);
        public static readonly Color Soft = Color.FromArgb(246, 248, 243);
        public static readonly Color SoftHover = Color.FromArgb(235, 240, 229);

        public static GraphicsPath RoundedRect(Rectangle rect, int radius)
        {
            int d = radius * 2;
            var path = new GraphicsPath();
            path.AddArc(rect.Left, rect.Top, d, d, 180, 90);
            path.AddArc(rect.Right - d, rect.Top, d, d, 270, 90);
            path.AddArc(rect.Right - d, rect.Bottom - d, d, d, 0, 90);
            path.AddArc(rect.Left, rect.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }

        public static Image LoadImage(string path)
        {
            if (!File.Exists(path)) return null;
            try
            {
                byte[] bytes = File.ReadAllBytes(path);
                using (var ms = new MemoryStream(bytes))
                {
                    return Image.FromStream(ms);
                }
            }
            catch
            {
                return null;
            }
        }
    }

    internal sealed class RoundedPanel : Panel
    {
        public Color FillColor = Ui.Card;
        public Color StrokeColor = Ui.Border;
        public int Radius = 14;

        public RoundedPanel()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            BackColor = Color.Transparent;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle rect = ClientRectangle;
            rect.Width -= 1;
            rect.Height -= 1;
            using (GraphicsPath path = Ui.RoundedRect(rect, Radius))
            using (SolidBrush brush = new SolidBrush(FillColor))
            using (Pen pen = new Pen(StrokeColor))
            {
                e.Graphics.FillPath(brush, path);
                e.Graphics.DrawPath(pen, path);
            }
        }
    }

    internal sealed class HeroPanel : Panel
    {
        public Image HeroImage;
        public Image LogoImage;

        public HeroPanel()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle rect = ClientRectangle;

            if (HeroImage != null)
            {
                Rectangle src = CoverSource(HeroImage.Size, rect.Size);
                e.Graphics.DrawImage(HeroImage, rect, src, GraphicsUnit.Pixel);
            }
            else
            {
                using (var brush = new LinearGradientBrush(rect, Color.FromArgb(85, 123, 96), Color.FromArgb(190, 142, 72), 0F))
                {
                    e.Graphics.FillRectangle(brush, rect);
                }
            }

            using (var overlay = new LinearGradientBrush(rect, Color.FromArgb(205, 24, 33, 30), Color.FromArgb(112, 24, 33, 30), 0F))
            {
                e.Graphics.FillRectangle(overlay, rect);
            }

            Rectangle logoRect = new Rectangle(26, 28, 56, 56);
            using (GraphicsPath logoPath = Ui.RoundedRect(logoRect, 18))
            using (var logoBack = new SolidBrush(Color.FromArgb(230, 255, 255, 250)))
            {
                e.Graphics.FillPath(logoBack, logoPath);
                if (LogoImage != null)
                {
                    Rectangle imageRect = new Rectangle(logoRect.X + 9, logoRect.Y + 9, 38, 38);
                    e.Graphics.DrawImage(LogoImage, imageRect);
                }
                else
                {
                    using (Font font = new Font("Segoe UI", 24F, FontStyle.Bold))
                    using (Brush brush = new SolidBrush(Ui.Green))
                    {
                        e.Graphics.DrawString("B", font, brush, logoRect.X + 15, logoRect.Y + 8);
                    }
                }
            }

            using (Font title = new Font("Microsoft YaHei UI", 22F, FontStyle.Bold))
            using (Font sub = new Font("Microsoft YaHei UI", 9.5F))
            using (Brush white = new SolidBrush(Color.White))
            using (Brush soft = new SolidBrush(Color.FromArgb(230, 255, 255, 255)))
            {
                e.Graphics.DrawString("Blog Manager", title, white, 98, 28);
                e.Graphics.DrawString("Hexo 本地写作控制台 · 文章、预览、Typora、发布都在这里", sub, soft, 101, 67);
            }
        }

        private static Rectangle CoverSource(Size image, Size target)
        {
            double targetRatio = target.Width / (double)Math.Max(1, target.Height);
            double imageRatio = image.Width / (double)Math.Max(1, image.Height);
            if (imageRatio > targetRatio)
            {
                int width = (int)(image.Height * targetRatio);
                return new Rectangle((image.Width - width) / 2, 0, width, image.Height);
            }
            int height = (int)(image.Width / targetRatio);
            return new Rectangle(0, (image.Height - height) / 2, image.Width, height);
        }
    }

    internal sealed class WallpaperPanel : Panel
    {
        public Image Wallpaper;

        public WallpaperPanel()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle rect = ClientRectangle;
            using (SolidBrush baseBrush = new SolidBrush(Ui.Page))
            {
                e.Graphics.FillRectangle(baseBrush, rect);
            }

            if (Wallpaper != null)
            {
                Rectangle src = CoverSource(Wallpaper.Size, rect.Size);
                e.Graphics.DrawImage(Wallpaper, rect, src, GraphicsUnit.Pixel);
                using (SolidBrush veil = new SolidBrush(Color.FromArgb(214, Ui.Page)))
                {
                    e.Graphics.FillRectangle(veil, rect);
                }
            }

            using (var glow = new LinearGradientBrush(rect, Color.FromArgb(70, 255, 255, 255), Color.FromArgb(18, 185, 137, 65), 35F))
            {
                e.Graphics.FillRectangle(glow, rect);
            }
        }

        private static Rectangle CoverSource(Size image, Size target)
        {
            double targetRatio = target.Width / (double)Math.Max(1, target.Height);
            double imageRatio = image.Width / (double)Math.Max(1, image.Height);
            if (imageRatio > targetRatio)
            {
                int width = (int)(image.Height * targetRatio);
                return new Rectangle((image.Width - width) / 2, 0, width, image.Height);
            }
            int height = (int)(image.Width / targetRatio);
            return new Rectangle(0, (image.Height - height) / 2, image.Width, height);
        }
    }

    internal sealed class SectionHeader : Control
    {
        public string TitleText = "";
        public string SubtitleText = "";

        public SectionHeader()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            Height = 50;
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using (Font title = new Font("Microsoft YaHei UI", 10.5F, FontStyle.Bold))
            using (Font sub = new Font("Microsoft YaHei UI", 8.5F))
            using (Brush titleBrush = new SolidBrush(Ui.Ink))
            using (Brush subBrush = new SolidBrush(Ui.Muted))
            {
                e.Graphics.DrawString(TitleText, title, titleBrush, 2, 2);
                if (SubtitleText.Length > 0)
                {
                    e.Graphics.DrawString(SubtitleText, sub, subBrush, 2, 25);
                }
            }
        }
    }

    internal sealed class ModernButton : Button
    {
        public Color BaseColor = Ui.Soft;
        public Color HoverColor = Ui.SoftHover;
        public Color PressedColor = Color.FromArgb(226, 232, 220);
        public Color TextColor = Ui.Ink;
        public int Radius = 10;
        private bool hovered;
        private bool pressed;

        public ModernButton()
        {
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.UserPaint | ControlStyles.OptimizedDoubleBuffer | ControlStyles.ResizeRedraw, true);
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            Font = new Font("Microsoft YaHei UI", 9F, FontStyle.Bold);
            Cursor = Cursors.Hand;
        }

        protected override void OnMouseEnter(EventArgs e)
        {
            hovered = true;
            Invalidate();
            base.OnMouseEnter(e);
        }

        protected override void OnMouseLeave(EventArgs e)
        {
            hovered = false;
            pressed = false;
            Invalidate();
            base.OnMouseLeave(e);
        }

        protected override void OnMouseDown(MouseEventArgs mevent)
        {
            pressed = true;
            Invalidate();
            base.OnMouseDown(mevent);
        }

        protected override void OnMouseUp(MouseEventArgs mevent)
        {
            pressed = false;
            Invalidate();
            base.OnMouseUp(mevent);
        }

        protected override void OnPaint(PaintEventArgs pevent)
        {
            pevent.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Rectangle rect = ClientRectangle;
            rect.Width -= 1;
            rect.Height -= 1;
            Color fill = !Enabled ? Color.FromArgb(229, 232, 226) : pressed ? PressedColor : hovered ? HoverColor : BaseColor;
            Color fore = !Enabled ? Color.FromArgb(145, 150, 141) : TextColor;

            using (GraphicsPath path = Ui.RoundedRect(rect, Radius))
            using (SolidBrush brush = new SolidBrush(fill))
            using (Pen pen = new Pen(Color.FromArgb(34, 255, 255, 255)))
            {
                pevent.Graphics.FillPath(brush, path);
                pevent.Graphics.DrawPath(pen, path);
            }

            int left = 13;
            if (Image != null)
            {
                Rectangle imageRect = new Rectangle(12, (Height - 18) / 2, 18, 18);
                pevent.Graphics.DrawImage(Image, imageRect);
                left = 36;
            }

            Rectangle textRect = new Rectangle(left, 0, Width - left - 10, Height);
            TextRenderer.DrawText(pevent.Graphics, Text, Font, textRect, fore, TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
        }
    }

    internal static class IconFactory
    {
        public static Image Create(string name, Color color)
        {
            var bitmap = new Bitmap(36, 36);
            using (Graphics g = Graphics.FromImage(bitmap))
            using (Pen pen = new Pen(color, 3F))
            using (SolidBrush brush = new SolidBrush(color))
            {
                g.SmoothingMode = SmoothingMode.AntiAlias;
                pen.StartCap = LineCap.Round;
                pen.EndCap = LineCap.Round;
                if (name == "new")
                {
                    g.DrawLine(pen, 18, 9, 18, 27);
                    g.DrawLine(pen, 9, 18, 27, 18);
                }
                else if (name == "edit")
                {
                    g.DrawLine(pen, 11, 25, 25, 11);
                    g.DrawLine(pen, 21, 9, 27, 15);
                    g.FillEllipse(brush, 9, 24, 5, 5);
                }
                else if (name == "folder")
                {
                    g.DrawRectangle(pen, 7, 13, 22, 15);
                    g.DrawLine(pen, 8, 13, 15, 9);
                    g.DrawLine(pen, 15, 9, 22, 13);
                }
                else if (name == "generate")
                {
                    g.DrawEllipse(pen, 8, 8, 20, 20);
                    g.DrawLine(pen, 18, 5, 18, 11);
                    g.DrawLine(pen, 18, 25, 18, 31);
                    g.DrawLine(pen, 5, 18, 11, 18);
                    g.DrawLine(pen, 25, 18, 31, 18);
                }
                else if (name == "browser")
                {
                    g.DrawEllipse(pen, 7, 7, 22, 22);
                    g.DrawArc(pen, 11, 7, 14, 22, 90, 180);
                    g.DrawArc(pen, 11, 7, 14, 22, 270, 180);
                    g.DrawLine(pen, 8, 18, 28, 18);
                }
                else if (name == "deploy")
                {
                    Point[] rocket = { new Point(18, 6), new Point(26, 25), new Point(18, 21), new Point(10, 25) };
                    g.DrawPolygon(pen, rocket);
                    g.FillEllipse(brush, 16, 13, 4, 4);
                    g.DrawLine(pen, 15, 25, 12, 31);
                    g.DrawLine(pen, 21, 25, 24, 31);
                }
                else if (name == "refresh")
                {
                    g.DrawArc(pen, 8, 8, 20, 20, 40, 255);
                    g.DrawLine(pen, 24, 8, 30, 8);
                    g.DrawLine(pen, 30, 8, 30, 14);
                }
                else if (name == "home")
                {
                    g.DrawLine(pen, 8, 18, 18, 9);
                    g.DrawLine(pen, 18, 9, 28, 18);
                    g.DrawRectangle(pen, 11, 18, 14, 11);
                }
                else if (name == "article")
                {
                    g.DrawRectangle(pen, 10, 7, 17, 22);
                    g.DrawLine(pen, 14, 14, 23, 14);
                    g.DrawLine(pen, 14, 19, 23, 19);
                    g.DrawLine(pen, 14, 24, 20, 24);
                }
                else if (name == "code")
                {
                    g.DrawLine(pen, 15, 11, 9, 18);
                    g.DrawLine(pen, 9, 18, 15, 25);
                    g.DrawLine(pen, 21, 11, 27, 18);
                    g.DrawLine(pen, 27, 18, 21, 25);
                }
                else if (name == "blog")
                {
                    g.DrawRectangle(pen, 8, 9, 20, 18);
                    g.DrawLine(pen, 12, 14, 24, 14);
                    g.DrawLine(pen, 12, 19, 22, 19);
                    g.FillEllipse(brush, 12, 23, 3, 3);
                }
                else if (name == "quote")
                {
                    g.DrawArc(pen, 9, 11, 8, 9, 90, 220);
                    g.DrawArc(pen, 20, 11, 8, 9, 90, 220);
                    g.DrawLine(pen, 13, 20, 10, 26);
                    g.DrawLine(pen, 24, 20, 21, 26);
                }
                else if (name == "journal")
                {
                    g.DrawEllipse(pen, 8, 8, 20, 20);
                    g.DrawLine(pen, 18, 12, 18, 18);
                    g.DrawLine(pen, 18, 18, 23, 21);
                }
                else if (name == "search")
                {
                    g.DrawEllipse(pen, 9, 9, 15, 15);
                    g.DrawLine(pen, 22, 22, 29, 29);
                }
            }
            return bitmap;
        }
    }

    internal sealed class NewPostDialog : Form
    {
        private readonly TextBox titleBox;
        private readonly ComboBox categoryBox;
        private readonly TextBox tagBox;
        private readonly CheckedListBox tagList;
        private readonly TextBox descriptionBox;
        private readonly TextBox coverBox;
        private readonly string blogRoot;
        private string selectedCoverSource;

        public string PostTitle { get { return titleBox.Text.Trim(); } }
        public string Categories { get { return categoryBox.Text.Trim(); } }
        public string Tags { get { return tagBox.Text.Trim(); } }
        public string Description { get { return descriptionBox.Text.Trim(); } }
        public string Cover { get { return coverBox.Text.Trim(); } }

        public NewPostDialog(IEnumerable<PostInfo> existingPosts, string root)
        {
            blogRoot = root;
            Text = "新建文章";
            StartPosition = FormStartPosition.CenterParent;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MinimizeBox = false;
            MaximizeBox = false;
            ClientSize = new Size(650, 430);
            Font = new Font("Microsoft YaHei UI", 9F);
            BackColor = Ui.Page;

            List<string> categories = CollectOptions(existingPosts, true);
            List<string> tags = CollectOptions(existingPosts, false);
            if (categories.Count == 0) categories.Add("随笔");

            var layout = new TableLayoutPanel();
            layout.Dock = DockStyle.Fill;
            layout.Padding = new Padding(20, 18, 20, 8);
            layout.BackColor = Ui.Page;
            layout.RowCount = 7;
            layout.ColumnCount = 3;
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 92));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 116));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 38));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 38));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 38));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 92));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 38));
            layout.RowStyles.Add(new RowStyle(SizeType.Absolute, 38));
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

            titleBox = AddRow(layout, 0, "标题", "");
            categoryBox = AddComboRow(layout, 1, "分类", categories, categories[0]);
            tagBox = AddRow(layout, 2, "标签", "");

            tagList = new CheckedListBox();
            tagList.CheckOnClick = true;
            tagList.BorderStyle = BorderStyle.FixedSingle;
            tagList.BackColor = Color.FromArgb(248, 250, 245);
            tagList.Font = new Font("Microsoft YaHei UI", 9F);
            tagList.Height = 84;
            tagList.Dock = DockStyle.Fill;
            tagList.MultiColumn = true;
            for (int i = 0; i < tags.Count; i++)
            {
                tagList.Items.Add(tags[i]);
            }
            tagList.ItemCheck += delegate { BeginInvoke((MethodInvoker)SyncCheckedTags); };

            var tagHint = new Label();
            tagHint.Text = "现有标签";
            tagHint.TextAlign = ContentAlignment.MiddleLeft;
            tagHint.Dock = DockStyle.Fill;
            tagHint.ForeColor = Ui.Muted;
            layout.Controls.Add(tagHint, 0, 3);
            layout.Controls.Add(tagList, 1, 3);
            layout.SetColumnSpan(tagList, 2);

            descriptionBox = AddRow(layout, 4, "摘要", "");
            coverBox = AddCoverRow(layout, 5);

            var hint = new Label();
            hint.Text = "分类可从现有选项选择，也可以直接输入新分类；标签可勾选后继续手动补充。";
            hint.AutoSize = true;
            hint.ForeColor = Color.FromArgb(90, 90, 90);
            hint.Dock = DockStyle.Top;
            layout.Controls.Add(hint, 1, 6);
            layout.SetColumnSpan(hint, 2);

            var buttons = new FlowLayoutPanel();
            buttons.FlowDirection = FlowDirection.RightToLeft;
            buttons.Dock = DockStyle.Bottom;
            buttons.Height = 58;
            buttons.Padding = new Padding(14, 10, 18, 10);
            buttons.BackColor = Ui.Page;

            var ok = new ModernButton();
            ok.Text = "创建";
            ok.Width = 104;
            ok.Height = 38;
            ok.Image = IconFactory.Create("new", Color.White);
            ok.BaseColor = Ui.Green;
            ok.HoverColor = Ui.GreenHover;
            ok.TextColor = Color.White;
            ok.DialogResult = DialogResult.OK;
            ok.Click += delegate
            {
                if (PostTitle.Length == 0)
                {
                    MessageBox.Show(this, "请先填写文章标题。", "缺少标题", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    DialogResult = DialogResult.None;
                }
            };

            var cancel = new ModernButton();
            cancel.Text = "取消";
            cancel.Width = 94;
            cancel.Height = 38;
            cancel.BaseColor = Ui.Soft;
            cancel.HoverColor = Ui.SoftHover;
            cancel.TextColor = Ui.Ink;
            cancel.DialogResult = DialogResult.Cancel;

            buttons.Controls.Add(ok);
            buttons.Controls.Add(cancel);

            Controls.Add(layout);
            Controls.Add(buttons);
            AcceptButton = ok;
            CancelButton = cancel;
        }

        private static TextBox AddRow(TableLayoutPanel layout, int row, string label, string value)
        {
            var lab = new Label();
            lab.Text = label;
            lab.TextAlign = ContentAlignment.MiddleLeft;
            lab.Dock = DockStyle.Fill;

            var box = new TextBox();
            box.Dock = DockStyle.Fill;
            box.Text = value;
            box.BorderStyle = BorderStyle.FixedSingle;
            box.Font = new Font("Microsoft YaHei UI", 10F);

            layout.Controls.Add(lab, 0, row);
            layout.Controls.Add(box, 1, row);
            layout.SetColumnSpan(box, 2);
            return box;
        }

        private ComboBox AddComboRow(TableLayoutPanel layout, int row, string label, List<string> values, string value)
        {
            var lab = new Label();
            lab.Text = label;
            lab.TextAlign = ContentAlignment.MiddleLeft;
            lab.Dock = DockStyle.Fill;

            var box = new ComboBox();
            box.Dock = DockStyle.Fill;
            box.DropDownStyle = ComboBoxStyle.DropDown;
            box.FlatStyle = FlatStyle.Flat;
            box.Font = new Font("Microsoft YaHei UI", 10F);
            for (int i = 0; i < values.Count; i++)
            {
                box.Items.Add(values[i]);
            }
            box.Text = value;

            layout.Controls.Add(lab, 0, row);
            layout.Controls.Add(box, 1, row);
            layout.SetColumnSpan(box, 2);
            return box;
        }

        private TextBox AddCoverRow(TableLayoutPanel layout, int row)
        {
            var lab = new Label();
            lab.Text = "封面";
            lab.TextAlign = ContentAlignment.MiddleLeft;
            lab.Dock = DockStyle.Fill;

            var box = new TextBox();
            box.Dock = DockStyle.Fill;
            box.Text = "/images/henan-wheatfield-bg.png";
            box.BorderStyle = BorderStyle.FixedSingle;
            box.Font = new Font("Microsoft YaHei UI", 10F);

            var browse = new ModernButton();
            browse.Text = "浏览图片";
            browse.Width = 104;
            browse.Height = 31;
            browse.Image = IconFactory.Create("folder", Ui.Ink);
            browse.BaseColor = Ui.Soft;
            browse.HoverColor = Ui.SoftHover;
            browse.TextColor = Ui.Ink;
            browse.Click += delegate { BrowseCoverImage(); };

            layout.Controls.Add(lab, 0, row);
            layout.Controls.Add(box, 1, row);
            layout.Controls.Add(browse, 2, row);
            return box;
        }

        private static List<string> CollectOptions(IEnumerable<PostInfo> posts, bool category)
        {
            var seen = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
            var values = new List<string>();
            foreach (PostInfo post in posts)
            {
                string raw = category ? post.Categories : post.Tags;
                string[] parts = Regex.Split(raw == null ? "" : raw, "[,，]");
                for (int i = 0; i < parts.Length; i++)
                {
                    string item = parts[i].Trim().Trim('"', '\'', '[', ']');
                    if (item.Length == 0 || seen.ContainsKey(item)) continue;
                    seen[item] = true;
                    values.Add(item);
                }
            }
            values.Sort(StringComparer.CurrentCultureIgnoreCase);
            return values;
        }

        private void SyncCheckedTags()
        {
            var values = new List<string>();
            var seen = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
            var existing = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < tagList.Items.Count; i++)
            {
                string item = tagList.Items[i].ToString();
                if (!existing.ContainsKey(item)) existing[item] = true;
            }

            for (int i = 0; i < tagList.CheckedItems.Count; i++)
            {
                string item = tagList.CheckedItems[i].ToString();
                if (!seen.ContainsKey(item))
                {
                    seen[item] = true;
                    values.Add(item);
                }
            }

            string[] typed = Regex.Split(tagBox.Text, "[,，]");
            for (int i = 0; i < typed.Length; i++)
            {
                string item = typed[i].Trim();
                if (item.Length == 0 || seen.ContainsKey(item)) continue;
                if (existing.ContainsKey(item)) continue;
                seen[item] = true;
                values.Add(item);
            }

            tagBox.Text = string.Join(", ", values.ToArray());
        }

        private void BrowseCoverImage()
        {
            using (var dialog = new OpenFileDialog())
            {
                dialog.Title = "选择封面图片";
                dialog.Filter = "图片文件|*.png;*.jpg;*.jpeg;*.gif;*.bmp;*.webp|所有文件|*.*";
                dialog.Multiselect = false;
                if (Directory.Exists(Path.Combine(blogRoot, "source", "images")))
                {
                    dialog.InitialDirectory = Path.Combine(blogRoot, "source", "images");
                }

                if (dialog.ShowDialog(this) != DialogResult.OK) return;
                selectedCoverSource = dialog.FileName;
                coverBox.Text = MakeUploadCoverPath(selectedCoverSource);
            }
        }

        public string SaveCoverToBlog()
        {
            string current = Cover;
            if (selectedCoverSource == null || selectedCoverSource.Length == 0) return current;
            if (!File.Exists(selectedCoverSource)) return current;

            string uploadDir = Path.Combine(blogRoot, "source", "images", "uploads");
            Directory.CreateDirectory(uploadDir);

            string fileName = Path.GetFileName(selectedCoverSource);
            string target = Path.Combine(uploadDir, fileName);
            if (!string.Equals(Path.GetFullPath(selectedCoverSource), Path.GetFullPath(target), StringComparison.OrdinalIgnoreCase))
            {
                target = UniqueImagePath(target);
                File.Copy(selectedCoverSource, target, false);
            }

            return "/images/uploads/" + Path.GetFileName(target).Replace("\\", "/");
        }

        private static string MakeUploadCoverPath(string path)
        {
            return "/images/uploads/" + Path.GetFileName(path);
        }

        private static string UniqueImagePath(string target)
        {
            if (!File.Exists(target)) return target;
            string dir = Path.GetDirectoryName(target);
            string name = Path.GetFileNameWithoutExtension(target);
            string ext = Path.GetExtension(target);
            int counter = 2;
            string candidate;
            do
            {
                candidate = Path.Combine(dir, name + "-" + counter + ext);
                counter++;
            } while (File.Exists(candidate));
            return candidate;
        }
    }

    internal sealed class MainForm : Form
    {
        private readonly string root;
        private readonly string postsDir;
        private readonly List<PostInfo> posts = new List<PostInfo>();

        private ListView listView;
        private TextBox searchBox;
        private WebBrowser preview;
        private TextBox logBox;
        private Label statusLabel;
        private Button editButton;
        private Button browserButton;
        private Button generateButton;
        private Button deployButton;
        private ImageList postIconList;

        public MainForm()
        {
            root = FindBlogRoot();
            postsDir = Path.Combine(root, "source", "_posts");

            Text = "Blog Manager - Hexo 本地文章管理";
            MinimumSize = new Size(1050, 680);
            Size = new Size(1220, 760);
            StartPosition = FormStartPosition.CenterScreen;
            Font = new Font("Microsoft YaHei UI", 9F);

            BuildUi();
            LoadPosts();
        }

        private static string FindBlogRoot()
        {
            string dir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar);
            for (int i = 0; i < 5 && dir != null; i++)
            {
                if (File.Exists(Path.Combine(dir, "_config.yml")) && Directory.Exists(Path.Combine(dir, "source")))
                {
                    return dir;
                }
                dir = Directory.GetParent(dir) == null ? null : Directory.GetParent(dir).FullName;
            }
            return Directory.GetCurrentDirectory();
        }

        private void BuildUi()
        {
            BackColor = Ui.Page;
            try
            {
                string iconPath = Path.Combine(root, "source", "images", "favicon.ico");
                if (File.Exists(iconPath)) Icon = new Icon(iconPath);
            }
            catch { }

            var hero = new HeroPanel();
            hero.Dock = DockStyle.Top;
            hero.Height = 124;
            hero.HeroImage = Ui.LoadImage(Path.Combine(root, "source", "images", "henan-wheatfield-bg.png"));
            hero.LogoImage = Ui.LoadImage(Path.Combine(root, "source", "images", "favicon.png"));

            var toolbarPanel = new Panel();
            toolbarPanel.Dock = DockStyle.Top;
            toolbarPanel.Height = 64;
            toolbarPanel.Padding = new Padding(16, 12, 16, 10);
            toolbarPanel.BackColor = Ui.Page;

            var toolbar = new FlowLayoutPanel();
            toolbar.Dock = DockStyle.Fill;
            toolbar.WrapContents = false;
            toolbar.BackColor = Ui.Page;

            var newButton = MakeButton("新建文章", 112, "new", Ui.Green, Ui.GreenHover, Color.White);
            newButton.Click += delegate { CreatePost(); };
            editButton = MakeButton("Typora 编辑", 128, "edit", Ui.Soft, Ui.SoftHover, Ui.Ink);
            editButton.Click += delegate { OpenSelectedInTypora(); };
            var folderButton = MakeButton("打开文件夹", 118, "folder", Ui.Soft, Ui.SoftHover, Ui.Ink);
            folderButton.Click += delegate { OpenSelectedFolder(); };
            generateButton = MakeButton("生成预览", 112, "generate", Ui.Blue, Ui.BlueHover, Color.White);
            generateButton.Click += delegate { GenerateSite(); };
            browserButton = MakeButton("浏览器预览", 128, "browser", Ui.Soft, Ui.SoftHover, Ui.Ink);
            browserButton.Click += delegate { OpenSelectedPublicPreview(); };
            deployButton = MakeButton("一键发布", 112, "deploy", Ui.Wheat, Ui.WheatHover, Color.White);
            deployButton.Click += delegate { Deploy(); };
            var refreshButton = MakeButton("刷新", 86, "refresh", Ui.Soft, Ui.SoftHover, Ui.Ink);
            refreshButton.Click += delegate { LoadPosts(); };
            var rootButton = MakeButton("博客目录", 104, "home", Ui.Soft, Ui.SoftHover, Ui.Ink);
            rootButton.Click += delegate { Process.Start(root); };

            toolbar.Controls.Add(newButton);
            toolbar.Controls.Add(editButton);
            toolbar.Controls.Add(folderButton);
            toolbar.Controls.Add(generateButton);
            toolbar.Controls.Add(browserButton);
            toolbar.Controls.Add(deployButton);
            toolbar.Controls.Add(refreshButton);
            toolbar.Controls.Add(rootButton);
            toolbarPanel.Controls.Add(toolbar);

            var content = new WallpaperPanel();
            content.Dock = DockStyle.Fill;
            content.Padding = new Padding(16, 0, 16, 14);
            content.BackColor = Ui.Page;
            content.Wallpaper = Ui.LoadImage(Path.Combine(root, "source", "images", "sakura-bg.jpg"));

            var split = new SplitContainer();
            split.Dock = DockStyle.Fill;
            split.SplitterDistance = 455;
            split.SplitterWidth = 10;
            split.BackColor = Ui.Page;
            split.Panel1.BackColor = Ui.Page;
            split.Panel2.BackColor = Ui.Page;

            var leftCard = new RoundedPanel();
            leftCard.Dock = DockStyle.Fill;
            leftCard.Padding = new Padding(15, 14, 15, 15);

            var leftTitle = MakeSectionLabel("文章库", "双击文章可直接用 Typora 编辑");
            leftTitle.Dock = DockStyle.Top;

            var searchShell = new RoundedPanel();
            searchShell.Dock = DockStyle.Top;
            searchShell.Height = 42;
            searchShell.Padding = new Padding(12, 9, 12, 6);
            searchShell.FillColor = Color.FromArgb(247, 249, 244);
            searchShell.StrokeColor = Color.FromArgb(226, 231, 220);
            searchShell.Radius = 12;

            var searchIcon = new PictureBox();
            searchIcon.Image = IconFactory.Create("search", Color.FromArgb(111, 119, 105));
            searchIcon.SizeMode = PictureBoxSizeMode.CenterImage;
            searchIcon.Dock = DockStyle.Left;
            searchIcon.Width = 28;

            searchBox = new TextBox();
            searchBox.BorderStyle = BorderStyle.None;
            searchBox.Dock = DockStyle.Fill;
            searchBox.BackColor = Color.FromArgb(247, 249, 244);
            searchBox.ForeColor = Ui.Ink;
            searchBox.Font = new Font("Microsoft YaHei UI", 10F);
            searchBox.Margin = new Padding(0);
            searchBox.TextChanged += delegate { ApplyFilter(); };
            searchShell.Controls.Add(searchBox);
            searchShell.Controls.Add(searchIcon);

            listView = new ListView();
            listView.Dock = DockStyle.Fill;
            listView.View = View.Details;
            listView.FullRowSelect = true;
            listView.HideSelection = false;
            listView.MultiSelect = false;
            listView.BorderStyle = BorderStyle.None;
            listView.BackColor = Ui.Card;
            listView.ForeColor = Ui.Ink;
            listView.Font = new Font("Microsoft YaHei UI", 9.5F);
            listView.GridLines = false;
            listView.OwnerDraw = true;
            listView.SmallImageList = BuildPostIconList();
            listView.DrawColumnHeader += DrawPostColumnHeader;
            listView.DrawItem += delegate(object sender, DrawListViewItemEventArgs e) { };
            listView.DrawSubItem += DrawPostSubItem;
            listView.Columns.Add("标题", 185);
            listView.Columns.Add("日期", 96);
            listView.Columns.Add("分类", 90);
            listView.Columns.Add("标签", 130);
            listView.Columns.Add("文件", 170);
            listView.SelectedIndexChanged += delegate { RenderSelectedPreview(); };
            listView.DoubleClick += delegate { OpenSelectedInTypora(); };

            var listSpacer = new Panel();
            listSpacer.Dock = DockStyle.Top;
            listSpacer.Height = 12;
            listSpacer.BackColor = Ui.Card;

            leftCard.Controls.Add(listView);
            leftCard.Controls.Add(listSpacer);
            leftCard.Controls.Add(searchShell);
            leftCard.Controls.Add(leftTitle);
            split.Panel1.Controls.Add(leftCard);

            var right = new SplitContainer();
            right.Dock = DockStyle.Fill;
            right.Orientation = Orientation.Horizontal;
            right.SplitterDistance = 465;
            right.SplitterWidth = 10;
            right.BackColor = Ui.Page;
            right.Panel1.BackColor = Ui.Page;
            right.Panel2.BackColor = Ui.Page;

            var previewCard = new RoundedPanel();
            previewCard.Dock = DockStyle.Fill;
            previewCard.Padding = new Padding(1);

            var previewTitle = MakeSectionLabel("文章预览", "这里是编辑前后的快速阅读视图");
            previewTitle.Dock = DockStyle.Top;
            previewTitle.Height = 48;

            preview = new WebBrowser();
            preview.Dock = DockStyle.Fill;
            preview.ScriptErrorsSuppressed = true;
            previewCard.Controls.Add(preview);
            previewCard.Controls.Add(previewTitle);
            right.Panel1.Controls.Add(previewCard);

            var logCard = new RoundedPanel();
            logCard.Dock = DockStyle.Fill;
            logCard.Padding = new Padding(14, 12, 14, 12);
            logCard.FillColor = Color.FromArgb(252, 253, 249);

            var logTitle = MakeSectionLabel("运行日志", "生成和发布结果会显示在这里");
            logTitle.Dock = DockStyle.Top;
            logTitle.Height = 44;

            logBox = new TextBox();
            logBox.Dock = DockStyle.Fill;
            logBox.Multiline = true;
            logBox.ScrollBars = ScrollBars.Vertical;
            logBox.ReadOnly = true;
            logBox.BorderStyle = BorderStyle.None;
            logBox.BackColor = Color.FromArgb(252, 253, 249);
            logBox.ForeColor = Color.FromArgb(58, 66, 55);
            logBox.Font = new Font("Consolas", 9F);
            logCard.Controls.Add(logBox);
            logCard.Controls.Add(logTitle);
            right.Panel2.Controls.Add(logCard);
            split.Panel2.Controls.Add(right);
            content.Controls.Add(split);

            statusLabel = new Label();
            statusLabel.Dock = DockStyle.Bottom;
            statusLabel.Height = 30;
            statusLabel.TextAlign = ContentAlignment.MiddleLeft;
            statusLabel.Padding = new Padding(18, 0, 0, 0);
            statusLabel.BackColor = Color.FromArgb(230, 234, 225);
            statusLabel.ForeColor = Color.FromArgb(71, 78, 67);

            Controls.Add(content);
            Controls.Add(statusLabel);
            Controls.Add(toolbarPanel);
            Controls.Add(hero);
        }

        private static Control MakeSectionLabel(string title, string subtitle)
        {
            var header = new SectionHeader();
            header.TitleText = title;
            header.SubtitleText = subtitle;
            return header;
        }

        private static Button MakeButton(string text, int width, string iconName, Color baseColor, Color hoverColor, Color textColor)
        {
            var button = new ModernButton();
            button.Text = text;
            button.Width = width;
            button.Height = 38;
            button.Margin = new Padding(0, 0, 10, 0);
            button.Image = IconFactory.Create(iconName, textColor);
            ((ModernButton)button).BaseColor = baseColor;
            ((ModernButton)button).HoverColor = hoverColor;
            ((ModernButton)button).PressedColor = ControlPaint.Dark(baseColor, 0.08F);
            ((ModernButton)button).TextColor = textColor;
            return button;
        }

        private ImageList BuildPostIconList()
        {
            postIconList = new ImageList();
            postIconList.ColorDepth = ColorDepth.Depth32Bit;
            postIconList.ImageSize = new Size(20, 20);
            postIconList.Images.Add("article", IconFactory.Create("article", Color.FromArgb(79, 120, 88)));
            postIconList.Images.Add("code", IconFactory.Create("code", Color.FromArgb(65, 101, 145)));
            postIconList.Images.Add("blog", IconFactory.Create("blog", Color.FromArgb(176, 128, 55)));
            postIconList.Images.Add("quote", IconFactory.Create("quote", Color.FromArgb(137, 92, 151)));
            postIconList.Images.Add("journal", IconFactory.Create("journal", Color.FromArgb(104, 113, 125)));
            return postIconList;
        }

        private static string GetPostIconKey(PostInfo post)
        {
            string text = (post.Title + " " + post.Categories + " " + post.Tags + " " + post.FileName).ToLowerInvariant();
            if (text.IndexOf("名言", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("quote", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("孔子", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return "quote";
            }
            if (text.IndexOf("深度学习", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("cnn", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("rag", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("transformer", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("模型", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return "code";
            }
            if (text.IndexOf("博客", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("blog", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return "blog";
            }
            if (text.IndexOf("日志", StringComparison.OrdinalIgnoreCase) >= 0 ||
                text.IndexOf("test", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                return "journal";
            }
            return "article";
        }

        private void DrawPostColumnHeader(object sender, DrawListViewColumnHeaderEventArgs e)
        {
            using (SolidBrush brush = new SolidBrush(Color.FromArgb(246, 248, 243)))
            using (Pen line = new Pen(Color.FromArgb(225, 230, 220)))
            {
                e.Graphics.FillRectangle(brush, e.Bounds);
                e.Graphics.DrawLine(line, e.Bounds.Left, e.Bounds.Bottom - 1, e.Bounds.Right, e.Bounds.Bottom - 1);
            }

            Rectangle textRect = new Rectangle(e.Bounds.Left + (e.ColumnIndex == 0 ? 30 : 8), e.Bounds.Top + 1, e.Bounds.Width - 12, e.Bounds.Height - 2);
            TextRenderer.DrawText(e.Graphics, e.Header.Text, new Font("Microsoft YaHei UI", 9F, FontStyle.Bold), textRect, Color.FromArgb(66, 73, 63), TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
        }

        private void DrawPostSubItem(object sender, DrawListViewSubItemEventArgs e)
        {
            bool selected = e.Item.Selected;
            Color back = selected ? Color.FromArgb(222, 236, 224) : (e.ItemIndex % 2 == 0 ? Color.FromArgb(255, 255, 252) : Color.FromArgb(249, 251, 246));
            Color fore = selected ? Color.FromArgb(28, 77, 48) : Ui.Ink;
            using (SolidBrush brush = new SolidBrush(back))
            using (Pen line = new Pen(Color.FromArgb(232, 236, 227)))
            {
                e.Graphics.FillRectangle(brush, e.Bounds);
                e.Graphics.DrawLine(line, e.Bounds.Left, e.Bounds.Bottom - 1, e.Bounds.Right, e.Bounds.Bottom - 1);
            }

            Rectangle textRect = new Rectangle(e.Bounds.Left + 8, e.Bounds.Top, e.Bounds.Width - 12, e.Bounds.Height);
            if (e.ColumnIndex == 0)
            {
                PostInfo post = e.Item.Tag as PostInfo;
                string iconKey = post == null ? "article" : GetPostIconKey(post);
                Image image = postIconList.Images[iconKey];
                int y = e.Bounds.Top + Math.Max(0, (e.Bounds.Height - 18) / 2);
                e.Graphics.DrawImage(image, new Rectangle(e.Bounds.Left + 8, y, 18, 18));
                textRect = new Rectangle(e.Bounds.Left + 32, e.Bounds.Top, e.Bounds.Width - 36, e.Bounds.Height);
            }

            if (e.ColumnIndex == 0)
            {
                using (Font font = new Font("Microsoft YaHei UI", 9.3F, FontStyle.Bold))
                {
                    TextRenderer.DrawText(e.Graphics, e.SubItem.Text, font, textRect, fore, TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
                }
            }
            else
            {
                TextRenderer.DrawText(e.Graphics, e.SubItem.Text, listView.Font, textRect, fore, TextFormatFlags.VerticalCenter | TextFormatFlags.Left | TextFormatFlags.EndEllipsis);
            }
        }

        private void LoadPosts()
        {
            posts.Clear();
            Directory.CreateDirectory(postsDir);

            string[] files = Directory.GetFiles(postsDir, "*.md", SearchOption.TopDirectoryOnly);
            Array.Sort(files, StringComparer.OrdinalIgnoreCase);

            for (int i = 0; i < files.Length; i++)
            {
                posts.Add(ReadPost(files[i]));
            }

            posts.Sort(delegate(PostInfo a, PostInfo b)
            {
                DateTime da;
                DateTime db;
                bool hasA = DateTime.TryParse(a.Date, out da);
                bool hasB = DateTime.TryParse(b.Date, out db);
                if (hasA && hasB) return db.CompareTo(da);
                return string.Compare(a.FileName, b.FileName, StringComparison.OrdinalIgnoreCase);
            });

            ApplyFilter();
            Log("已加载 " + posts.Count + " 篇文章。");
        }

        private PostInfo ReadPost(string file)
        {
            string text = ReadText(file);
            Dictionary<string, string> meta = ParseFrontMatter(text);
            var info = new PostInfo();
            info.FilePath = file;
            info.FileName = Path.GetFileName(file);
            info.Slug = Path.GetFileNameWithoutExtension(file);
            info.Title = CleanYamlValue(GetMeta(meta, "title"));
            if (info.Title.Length == 0) info.Title = info.Slug;
            info.Date = CleanYamlValue(GetMeta(meta, "date"));
            info.Updated = CleanYamlValue(GetMeta(meta, "updated"));
            info.Categories = CleanArray(GetMeta(meta, "categories"));
            info.Tags = CleanArray(GetMeta(meta, "tags"));
            info.Description = CleanYamlValue(GetMeta(meta, "description"));
            info.Modified = File.GetLastWriteTime(file);
            return info;
        }

        private static string ReadText(string file)
        {
            using (var reader = new StreamReader(file, new UTF8Encoding(false), true))
            {
                return reader.ReadToEnd();
            }
        }

        private static Dictionary<string, string> ParseFrontMatter(string text)
        {
            var meta = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            using (var reader = new StringReader(text))
            {
                string first = reader.ReadLine();
                if (first == null || first.Trim() != "---") return meta;

                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    if (line.Trim() == "---") break;
                    int colon = line.IndexOf(':');
                    if (colon <= 0) continue;
                    string key = line.Substring(0, colon).Trim();
                    string value = line.Substring(colon + 1).Trim();
                    meta[key] = value;
                }
            }
            return meta;
        }

        private static string GetMeta(Dictionary<string, string> meta, string key)
        {
            string value;
            return meta.TryGetValue(key, out value) ? value : "";
        }

        private static string CleanYamlValue(string value)
        {
            if (value == null) return "";
            value = value.Trim();
            if (value.Length >= 2)
            {
                if ((value[0] == '"' && value[value.Length - 1] == '"') ||
                    (value[0] == '\'' && value[value.Length - 1] == '\''))
                {
                    value = value.Substring(1, value.Length - 2);
                }
            }
            return value.Replace("\\\"", "\"");
        }

        private static string CleanArray(string value)
        {
            value = CleanYamlValue(value);
            if (value.StartsWith("[") && value.EndsWith("]"))
            {
                value = value.Substring(1, value.Length - 2);
            }
            value = value.Replace("\"", "").Replace("'", "");
            value = Regex.Replace(value, "\\s*,\\s*", ", ");
            return value.Trim();
        }

        private void ApplyFilter()
        {
            string needle = searchBox == null ? "" : searchBox.Text.Trim().ToLowerInvariant();
            listView.BeginUpdate();
            listView.Items.Clear();

            for (int i = 0; i < posts.Count; i++)
            {
                PostInfo post = posts[i];
                string haystack = (post.Title + " " + post.Categories + " " + post.Tags + " " + post.FileName).ToLowerInvariant();
                if (needle.Length > 0 && haystack.IndexOf(needle) < 0) continue;

                var item = new ListViewItem(post.Title);
                item.ImageKey = GetPostIconKey(post);
                item.SubItems.Add(ShortDate(post.Date));
                item.SubItems.Add(post.Categories);
                item.SubItems.Add(post.Tags);
                item.SubItems.Add(post.FileName);
                item.Tag = post;
                listView.Items.Add(item);
            }

            listView.EndUpdate();
            statusLabel.Text = "博客目录：" + root + "    文章：" + listView.Items.Count + "/" + posts.Count;
            if (listView.Items.Count > 0 && listView.SelectedItems.Count == 0)
            {
                listView.Items[0].Selected = true;
            }
        }

        private static string ShortDate(string value)
        {
            if (value == null) return "";
            value = value.Trim().Trim('"');
            return value.Length > 10 ? value.Substring(0, 10) : value;
        }

        private PostInfo SelectedPost()
        {
            if (listView.SelectedItems.Count == 0) return null;
            return listView.SelectedItems[0].Tag as PostInfo;
        }

        private void RenderSelectedPreview()
        {
            PostInfo post = SelectedPost();
            if (post == null) return;
            string markdown = ReadText(post.FilePath);
            preview.DocumentText = BuildPreviewHtml(post, markdown);
            statusLabel.Text = "当前文章：" + post.FileName + "    修改时间：" + post.Modified.ToString("yyyy-MM-dd HH:mm:ss");
        }

        private string BuildPreviewHtml(PostInfo post, string markdown)
        {
            string body = MarkdownToHtml(RemoveFrontMatter(markdown), post.FilePath);
            string title = WebUtility.HtmlEncode(post.Title);
            string description = WebUtility.HtmlEncode(post.Description);
            string meta = "";
            if (post.Categories.Length > 0) meta += "<span>" + WebUtility.HtmlEncode(post.Categories) + "</span>";
            if (post.Tags.Length > 0) meta += "<span>" + WebUtility.HtmlEncode(post.Tags) + "</span>";
            if (post.Date.Length > 0) meta += "<span>" + WebUtility.HtmlEncode(ShortDate(post.Date)) + "</span>";

            return "<!doctype html><html><head><meta charset=\"utf-8\"><style>" +
                   "body{font-family:'Microsoft YaHei UI','Segoe UI',Arial,sans-serif;margin:0;background:#fbfbfd;color:#202124;}" +
                   "main{max-width:850px;margin:0 auto;padding:34px 42px 70px;background:white;min-height:100vh;box-sizing:border-box;}" +
                   "h1{font-size:30px;line-height:1.32;margin:0 0 12px;}h2{font-size:23px;margin-top:32px;border-bottom:1px solid #eceff3;padding-bottom:8px;}h3{font-size:19px;margin-top:26px;}" +
                   "p,li{font-size:16px;line-height:1.85;}p{margin:13px 0;}img{max-width:100%;border-radius:6px;margin:12px 0;}" +
                   "pre{background:#111827;color:#f9fafb;padding:16px;border-radius:6px;overflow:auto;}code{font-family:Consolas,monospace;background:#f1f3f5;padding:2px 5px;border-radius:4px;}pre code{background:transparent;padding:0;}" +
                   "blockquote{border-left:4px solid #d0d7de;margin:16px 0;padding:2px 16px;color:#57606a;background:#f6f8fa;}.meta{display:flex;gap:10px;flex-wrap:wrap;color:#6b7280;margin-bottom:20px;}.meta span{background:#f1f4f8;border:1px solid #e2e8f0;border-radius:16px;padding:3px 10px;font-size:13px;}" +
                   ".desc{color:#4b5563;font-size:15px;line-height:1.7;margin:0 0 18px;}" +
                   "</style></head><body><main><h1>" + title + "</h1><div class=\"meta\">" + meta + "</div>" +
                   (description.Length > 0 ? "<p class=\"desc\">" + description + "</p>" : "") +
                   body + "</main></body></html>";
        }

        private static string RemoveFrontMatter(string markdown)
        {
            using (var reader = new StringReader(markdown))
            {
                string first = reader.ReadLine();
                if (first == null || first.Trim() != "---") return markdown;
                string line;
                while ((line = reader.ReadLine()) != null)
                {
                    if (line.Trim() == "---") break;
                }
                return reader.ReadToEnd();
            }
        }

        private string MarkdownToHtml(string markdown, string filePath)
        {
            var html = new StringBuilder();
            bool inCode = false;
            string listTag = null;
            string[] lines = markdown.Replace("\r\n", "\n").Replace('\r', '\n').Split('\n');

            for (int i = 0; i < lines.Length; i++)
            {
                string line = lines[i];
                string trim = line.Trim();

                if (trim.StartsWith("```"))
                {
                    if (inCode)
                    {
                        html.AppendLine("</code></pre>");
                        inCode = false;
                    }
                    else
                    {
                        CloseList(html, ref listTag);
                        html.AppendLine("<pre><code>");
                        inCode = true;
                    }
                    continue;
                }

                if (inCode)
                {
                    html.AppendLine(WebUtility.HtmlEncode(line));
                    continue;
                }

                if (trim.Length == 0)
                {
                    CloseList(html, ref listTag);
                    continue;
                }

                Match heading = Regex.Match(trim, "^(#{1,6})\\s+(.+)$");
                if (heading.Success)
                {
                    CloseList(html, ref listTag);
                    int level = heading.Groups[1].Value.Length;
                    html.Append("<h").Append(level).Append(">")
                        .Append(InlineMarkdown(heading.Groups[2].Value, filePath))
                        .Append("</h").Append(level).AppendLine(">");
                    continue;
                }

                Match imageOnly = Regex.Match(trim, "^!\\[(.*?)\\]\\((.*?)\\)$");
                if (imageOnly.Success)
                {
                    CloseList(html, ref listTag);
                    html.Append("<p>").Append(ImageHtml(imageOnly.Groups[1].Value, imageOnly.Groups[2].Value, filePath)).AppendLine("</p>");
                    continue;
                }

                Match ul = Regex.Match(trim, "^[-*+]\\s+(.+)$");
                if (ul.Success)
                {
                    OpenList(html, ref listTag, "ul");
                    html.Append("<li>").Append(InlineMarkdown(ul.Groups[1].Value, filePath)).AppendLine("</li>");
                    continue;
                }

                Match ol = Regex.Match(trim, "^\\d+\\.\\s+(.+)$");
                if (ol.Success)
                {
                    OpenList(html, ref listTag, "ol");
                    html.Append("<li>").Append(InlineMarkdown(ol.Groups[1].Value, filePath)).AppendLine("</li>");
                    continue;
                }

                if (trim.StartsWith(">"))
                {
                    CloseList(html, ref listTag);
                    html.Append("<blockquote><p>").Append(InlineMarkdown(trim.TrimStart('>').Trim(), filePath)).AppendLine("</p></blockquote>");
                    continue;
                }

                CloseList(html, ref listTag);
                html.Append("<p>").Append(InlineMarkdown(trim, filePath)).AppendLine("</p>");
            }

            if (inCode) html.AppendLine("</code></pre>");
            CloseList(html, ref listTag);
            return html.ToString();
        }

        private static void OpenList(StringBuilder html, ref string current, string wanted)
        {
            if (current == wanted) return;
            CloseList(html, ref current);
            html.Append("<").Append(wanted).AppendLine(">");
            current = wanted;
        }

        private static void CloseList(StringBuilder html, ref string current)
        {
            if (current == null) return;
            html.Append("</").Append(current).AppendLine(">");
            current = null;
        }

        private string InlineMarkdown(string text, string filePath)
        {
            text = WebUtility.HtmlEncode(text);
            text = Regex.Replace(text, "!\\[(.*?)\\]\\((.*?)\\)", delegate(Match m)
            {
                return ImageHtml(WebUtility.HtmlDecode(m.Groups[1].Value), WebUtility.HtmlDecode(m.Groups[2].Value), filePath);
            });
            text = Regex.Replace(text, "`([^`]+)`", "<code>$1</code>");
            text = Regex.Replace(text, "\\*\\*([^*]+)\\*\\*", "<strong>$1</strong>");
            text = Regex.Replace(text, "\\[([^\\]]+)\\]\\(([^\\)]+)\\)", delegate(Match m)
            {
                string href = WebUtility.HtmlEncode(WebUtility.HtmlDecode(m.Groups[2].Value));
                return "<a href=\"" + href + "\">" + m.Groups[1].Value + "</a>";
            });
            return text;
        }

        private string ImageHtml(string alt, string src, string filePath)
        {
            string resolved = ResolveImageSource(src, filePath);
            return "<img alt=\"" + WebUtility.HtmlEncode(alt) + "\" src=\"" + WebUtility.HtmlEncode(resolved) + "\">";
        }

        private string ResolveImageSource(string src, string filePath)
        {
            src = src.Trim().Trim('"');
            if (src.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                src.StartsWith("https://", StringComparison.OrdinalIgnoreCase) ||
                src.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
            {
                return src;
            }

            string candidate;
            if (src.StartsWith("/"))
            {
                candidate = Path.Combine(root, "source", src.TrimStart('/', '\\').Replace('/', Path.DirectorySeparatorChar));
            }
            else
            {
                candidate = Path.Combine(Path.GetDirectoryName(filePath), src.Replace('/', Path.DirectorySeparatorChar));
            }

            if (!File.Exists(candidate))
            {
                string sourceCandidate = Path.Combine(root, "source", src.TrimStart('/', '\\').Replace('/', Path.DirectorySeparatorChar));
                if (File.Exists(sourceCandidate)) candidate = sourceCandidate;
            }
            if (!File.Exists(candidate))
            {
                string publicCandidate = Path.Combine(root, "public", src.TrimStart('/', '\\').Replace('/', Path.DirectorySeparatorChar));
                if (File.Exists(publicCandidate)) candidate = publicCandidate;
            }

            try { return new Uri(candidate).AbsoluteUri; }
            catch { return src; }
        }

        private void CreatePost()
        {
            using (var dialog = new NewPostDialog(posts, root))
            {
                if (dialog.ShowDialog(this) != DialogResult.OK) return;

                Directory.CreateDirectory(postsDir);
                string slug = MakeSlug(dialog.PostTitle);
                string file = UniquePostPath(slug);
                string now = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
                string cover = dialog.SaveCoverToBlog();
                string body = BuildNewPostContent(dialog, now, cover);
                File.WriteAllText(file, body, new UTF8Encoding(false));
                Log("已创建文章：" + file);
                LoadPosts();
                SelectPostByPath(file);
                OpenFileInTypora(file);
            }
        }

        private static string MakeSlug(string title)
        {
            string slug = title.Trim().ToLowerInvariant();
            slug = Regex.Replace(slug, "[\\\\/:*?\"<>|]+", "-");
            slug = Regex.Replace(slug, "\\s+", "-");
            slug = slug.Trim('-', '.', ' ');
            if (slug.Length == 0) slug = DateTime.Now.ToString("yyyyMMdd-HHmmss");
            return slug;
        }

        private string UniquePostPath(string slug)
        {
            string path = Path.Combine(postsDir, slug + ".md");
            int counter = 2;
            while (File.Exists(path))
            {
                path = Path.Combine(postsDir, slug + "-" + counter + ".md");
                counter++;
            }
            return path;
        }

        private static string BuildNewPostContent(NewPostDialog dialog, string now, string cover)
        {
            var sb = new StringBuilder();
            cover = cover.Length == 0 ? "/images/henan-wheatfield-bg.png" : cover;
            sb.AppendLine("---");
            sb.AppendLine("title: \"" + EscapeYaml(dialog.PostTitle) + "\"");
            sb.AppendLine("date: \"" + now + "\"");
            sb.AppendLine("updated: \"" + now + "\"");
            sb.AppendLine("categories: " + ToYamlArray(dialog.Categories.Length == 0 ? "随笔" : dialog.Categories));
            sb.AppendLine("tags: " + ToYamlArray(dialog.Tags));
            sb.AppendLine("description: \"" + EscapeYaml(dialog.Description) + "\"");
            sb.AppendLine("cover: \"" + EscapeYaml(cover) + "\"");
            sb.AppendLine("top_img: \"" + EscapeYaml(cover) + "\"");
            sb.AppendLine("sticky: 0");
            sb.AppendLine("top: false");
            sb.AppendLine("---");
            sb.AppendLine();
            sb.AppendLine("从这里开始写正文。");
            return sb.ToString();
        }

        private static string ToYamlArray(string value)
        {
            value = value.Trim();
            if (value.Length == 0) return "[]";
            string[] parts = Regex.Split(value, "[,，]");
            var items = new List<string>();
            for (int i = 0; i < parts.Length; i++)
            {
                string item = parts[i].Trim();
                if (item.Length > 0) items.Add("\"" + EscapeYaml(item) + "\"");
            }
            return "[" + string.Join(", ", items.ToArray()) + "]";
        }

        private static string EscapeYaml(string value)
        {
            if (value == null) return "";
            return value.Replace("\\", "\\\\").Replace("\"", "\\\"");
        }

        private void SelectPostByPath(string path)
        {
            for (int i = 0; i < listView.Items.Count; i++)
            {
                PostInfo post = listView.Items[i].Tag as PostInfo;
                if (post != null && string.Equals(post.FilePath, path, StringComparison.OrdinalIgnoreCase))
                {
                    listView.Items[i].Selected = true;
                    listView.Items[i].EnsureVisible();
                    break;
                }
            }
        }

        private void OpenSelectedInTypora()
        {
            PostInfo post = SelectedPost();
            if (post == null) return;
            OpenFileInTypora(post.FilePath);
        }

        private void OpenFileInTypora(string file)
        {
            string typora = FindTypora();
            try
            {
                if (typora.Length > 0)
                {
                    var psi = new ProcessStartInfo();
                    psi.FileName = typora;
                    psi.Arguments = "\"" + file + "\"";
                    psi.WorkingDirectory = Path.GetDirectoryName(file);
                    Process.Start(psi);
                    Log("已用 Typora 打开：" + Path.GetFileName(file));
                }
                else
                {
                    Process.Start(file);
                    Log("未找到 Typora，已使用系统默认程序打开：" + Path.GetFileName(file));
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, ex.Message, "打开失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private static string FindTypora()
        {
            string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string pf = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles);
            string pfx86 = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
            string[] candidates = new string[]
            {
                Path.Combine(pf, "Typora", "Typora.exe"),
                Path.Combine(pfx86, "Typora", "Typora.exe"),
                Path.Combine(local, "Programs", "Typora", "Typora.exe")
            };
            for (int i = 0; i < candidates.Length; i++)
            {
                if (File.Exists(candidates[i])) return candidates[i];
            }
            return "";
        }

        private void OpenSelectedFolder()
        {
            PostInfo post = SelectedPost();
            if (post == null) return;
            Process.Start("explorer.exe", "/select,\"" + post.FilePath + "\"");
        }

        private void OpenSelectedPublicPreview()
        {
            PostInfo post = SelectedPost();
            if (post == null) return;
            string html = Path.Combine(root, "public", "posts", post.Slug, "index.html");
            if (!File.Exists(html))
            {
                Log("未找到生成后的页面，请先点击“生成预览”： " + html);
                MessageBox.Show(this, "还没有找到这篇文章的生成页面，请先点击“生成预览”。", "需要生成", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }
            Process.Start(html);
        }

        private void GenerateSite()
        {
            if (!File.Exists(Path.Combine(root, "node_modules", ".bin", "hexo.cmd")))
            {
                MessageBox.Show(this, "未找到 node_modules\\.bin\\hexo.cmd，无法生成预览。", "缺少 Hexo", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }
            RunBackground("生成预览", delegate
            {
                string sync = Path.Combine(root, "sync-typora-assets.ps1");
                if (File.Exists(sync))
                {
                    RunProcess("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -File \"" + sync + "\"");
                }
                string hexo = Path.Combine(root, "node_modules", ".bin", "hexo.cmd");
                RunProcess("cmd.exe", "/c \"" + hexo + "\" generate");
            });
        }

        private void Deploy()
        {
            string bat = Path.Combine(root, "deploy-baota.bat");
            if (!File.Exists(bat))
            {
                MessageBox.Show(this, "未找到 deploy-baota.bat。", "无法发布", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                var psi = new ProcessStartInfo();
                psi.FileName = bat;
                psi.WorkingDirectory = root;
                psi.UseShellExecute = true;
                Process.Start(psi);
                Log("已启动发布脚本：deploy-baota.bat");
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, ex.Message, "发布失败", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private delegate void Work();

        private void RunBackground(string title, Work work)
        {
            SetBusy(true);
            Log("开始：" + title);
            ThreadPool.QueueUserWorkItem(delegate
            {
                try
                {
                    work();
                    Log("完成：" + title);
                }
                catch (Exception ex)
                {
                    Log("失败：" + ex.Message);
                }
                finally
                {
                    if (IsHandleCreated)
                    {
                        BeginInvoke((MethodInvoker)delegate { SetBusy(false); LoadPosts(); });
                    }
                }
            });
        }

        private void SetBusy(bool busy)
        {
            generateButton.Enabled = !busy;
            deployButton.Enabled = !busy;
            editButton.Enabled = !busy;
            browserButton.Enabled = !busy;
            statusLabel.Text = busy ? "正在执行，请稍候..." : "就绪";
        }

        private void RunProcess(string fileName, string arguments)
        {
            var psi = new ProcessStartInfo();
            psi.FileName = fileName;
            psi.Arguments = arguments;
            psi.WorkingDirectory = root;
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;
            psi.CreateNoWindow = true;
            psi.StandardOutputEncoding = Encoding.UTF8;
            psi.StandardErrorEncoding = Encoding.UTF8;

            using (var process = new Process())
            {
                process.StartInfo = psi;
                process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e)
                {
                    if (e.Data != null) Log(e.Data);
                };
                process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e)
                {
                    if (e.Data != null) Log(e.Data);
                };
                process.Start();
                process.BeginOutputReadLine();
                process.BeginErrorReadLine();
                process.WaitForExit();
                if (process.ExitCode != 0)
                {
                    throw new InvalidOperationException(Path.GetFileName(fileName) + " exited with code " + process.ExitCode);
                }
            }
        }

        private void Log(string message)
        {
            if (InvokeRequired)
            {
                BeginInvoke((MethodInvoker)delegate { Log(message); });
                return;
            }
            logBox.AppendText("[" + DateTime.Now.ToString("HH:mm:ss") + "] " + message + Environment.NewLine);
        }
    }
}
