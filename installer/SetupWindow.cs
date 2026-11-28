using System;
using System.Drawing;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;
using System.Threading.Tasks;

internal static class Program {
    [STAThread] static void Main(string[] args) {
        Application.SetCompatibleTextRenderingDefault(false);
#if CRT
        const bool crt = true;
#else
        const bool crt = false;
#endif
        using (var form = new SetupWindow(crt)) {
            if (args.Length == 2 && args[0] == "--snapshot") {
                form.Shown += delegate {
                    form.BeginInvoke((Action)delegate {
                        using (var bitmap = new Bitmap(form.Width, form.Height)) {
                            form.DrawToBitmap(bitmap, new Rectangle(0,0,bitmap.Width,bitmap.Height));
                            bitmap.Save(args[1], System.Drawing.Imaging.ImageFormat.Png);
                        }
                        form.Close();
                    });
                };
            }
            Application.Run(form);
        }
    }
}
internal sealed class SegmentBar : Control {
    internal bool Retro;
    private int value;
    internal int Value { get { return value; } set { this.value = Math.Max(0,Math.Min(100,value)); Invalidate(); } }
    public SegmentBar() { DoubleBuffered = true; }
    protected override void OnPaint(PaintEventArgs e) {
        e.Graphics.Clear(Retro ? Color.Silver : Color.FromArgb(6,18,11));
        using(var pen=new Pen(Retro?Color.Gray:Color.FromArgb(80,125,89))) e.Graphics.DrawRectangle(pen,0,0,Width-1,Height-1);
        for(int i=0;i<24;i++){
            int x1=3+i*(Width-6)/24, x2=3+(i+1)*(Width-6)/24;
            using(var brush=new SolidBrush(i<value*24/100 ?
                (Retro?Color.Navy:Color.FromArgb(151,220,151)) :
                (Retro?Color.FromArgb(190,190,190):Color.FromArgb(20,42,25))))
                e.Graphics.FillRectangle(brush,x1,3,Math.Max(1,x2-x1-2),Height-6);
        }
    }
}
internal sealed class SetupWindow : Form {
    readonly bool crt;
    readonly Color bg,panel,fg,muted;
    readonly Font normal,heading;
    readonly Label subtitle,artCaption,pathLabel,statusLabel,percent,languageLabel;
    readonly TextBox path;
    readonly ComboBox language;
    readonly CheckBox shortcut,launch;
    readonly Button browse,install,cancel;
    readonly SegmentBar progress;
    readonly Timer timer;
    readonly Image artImage;
    bool busy,done;
    string tempDir,progressPath;
    bool Ukrainian { get { return language.SelectedIndex==1; } }
    string T(string en,string uk) { return Ukrainian?uk:en; }
    static Stream Resource(string name) {
        var stream=Assembly.GetExecutingAssembly().GetManifestResourceStream(name);
        if(stream==null) throw new InvalidDataException("Missing embedded resource: "+name);
        return stream;
    }
    Label LabelAt(string text,int x,int y,int w,int h,Font font) {
        var item=new Label { Text=text, Location=new Point(x,y), Size=new Size(w,h), ForeColor=fg, BackColor=bg, Font=font };
        Controls.Add(item); return item;
    }
    Button ButtonAt(int x,int y,int w,int h) {
        var item=new Button { Location=new Point(x,y), Size=new Size(w,h), Font=normal, ForeColor=fg,
            BackColor=crt?panel:Color.Silver, FlatStyle=crt?FlatStyle.Flat:FlatStyle.Standard };
        if(crt) { item.FlatAppearance.BorderColor=Color.FromArgb(90,142,99); item.FlatAppearance.MouseOverBackColor=Color.FromArgb(31,65,39); }
        Controls.Add(item); return item;
    }
    internal SetupWindow(bool crtMode) {
        crt=crtMode; bg=crt?Color.FromArgb(8,23,16):Color.Silver;
        panel=crt?Color.FromArgb(15,39,23):Color.FromArgb(224,224,224);
        fg=crt?Color.FromArgb(182,237,177):Color.Black;
        muted=crt?Color.FromArgb(130,174,139):Color.FromArgb(65,65,65);
        normal=new Font(crt?"Consolas":"Tahoma",10);
        heading=new Font(crt?"Consolas":"Tahoma",21,FontStyle.Bold);
        Font=normal; Text=crt?"SAPERROR // SETUP":"SAPERROR Setup";
        BackColor=bg; ForeColor=fg; ClientSize=new Size(900,536);
        FormBorderStyle=FormBorderStyle.FixedDialog; MaximizeBox=false; MinimizeBox=true;
        StartPosition=FormStartPosition.CenterScreen; AutoScaleMode=AutoScaleMode.Dpi;
        Icon=System.Drawing.Icon.ExtractAssociatedIcon(Application.ExecutablePath);
        var title=LabelAt("SAPERROR",22,15,856,43,heading);
        if(!crt) { title.BackColor=Color.Navy; title.ForeColor=Color.White; }
        subtitle=LabelAt("",24,65,850,30,normal);
        var art=new PictureBox { Location=new Point(24,112), Size=new Size(416,234), SizeMode=PictureBoxSizeMode.Zoom,
            BackColor=Color.Black, BorderStyle=BorderStyle.FixedSingle };
        using(var stream=Resource("setup.art")) using(var original=Image.FromStream(stream)) artImage=new Bitmap(original);
        art.Image=artImage; Controls.Add(art);
        artCaption=LabelAt("",24,358,416,60,normal); artCaption.ForeColor=muted;
        languageLabel=LabelAt("",463,106,170,24,normal);
        language=new ComboBox { Location=new Point(645,103), Size=new Size(230,30), DropDownStyle=ComboBoxStyle.DropDownList, BackColor=panel, ForeColor=fg, Font=normal };
        language.Items.AddRange(new object[]{"English","Українська"}); Controls.Add(language);
        pathLabel=LabelAt("",463,150,412,25,normal);
        path=new TextBox { Location=new Point(463,178), Size=new Size(306,27), Text=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Programs","SAPERROR"), Font=normal, BackColor=crt?panel:Color.White, ForeColor=fg };
        Controls.Add(path); browse=ButtonAt(778,176,97,30);
        shortcut=new CheckBox { Location=new Point(463,225), Size=new Size(412,30), Font=normal, ForeColor=fg, BackColor=bg, Checked=true }; Controls.Add(shortcut);
        launch=new CheckBox { Location=new Point(463,265), Size=new Size(412,30), Font=normal, ForeColor=fg, BackColor=bg, Checked=true }; Controls.Add(launch);
        statusLabel=LabelAt("",463,315,412,90,normal);
        progress=new SegmentBar { Location=new Point(24,431), Size=new Size(790,24), Retro=!crt }; Controls.Add(progress);
        percent=LabelAt("0%",825,432,65,23,normal);
        install=ButtonAt(537,478,164,39); cancel=ButtonAt(711,478,164,39);
        language.SelectedIndexChanged+=delegate { Localize(); };
        browse.Click+=delegate {
            using(var picker=new FolderBrowserDialog()){
                picker.Description=T("Select the SAPERROR installation folder","Оберіть папку встановлення SAPERROR");
                if(Directory.Exists(path.Text)) picker.SelectedPath=path.Text;
                if(picker.ShowDialog(this)==DialogResult.OK) path.Text=picker.SelectedPath;
            }
        };
        install.Click+=async delegate {
            if(done) { try { if(launch.Checked) Process.Start(new ProcessStartInfo(Path.Combine(path.Text,"SAPERROR.exe")) { WorkingDirectory=path.Text }); Close(); } catch(Exception ex) { MessageBox.Show(this,ex.Message,Text); } }
            else await InstallGame();
        };
        cancel.Click+=delegate { Close(); };
        FormClosing+=delegate(object sender,FormClosingEventArgs e){ if(busy) e.Cancel=true; };
        timer=new Timer { Interval=120 };
        timer.Tick+=delegate { try { int p; if(progressPath!=null && File.Exists(progressPath) && Int32.TryParse(File.ReadAllText(progressPath),out p)) SetProgress(Math.Min(p,99)); } catch(IOException){} };
        language.SelectedIndex=System.Globalization.CultureInfo.CurrentUICulture.TwoLetterISOLanguageName=="uk"?1:0;
        Localize();
    }
    void Localize(){
        subtitle.Text=crt?T("SYSTEM INSTALLATION // CRT TERMINAL","ВСТАНОВЛЕННЯ // CRT TERMINAL"):T("Welcome to the SAPERROR Setup Wizard","Майстер встановлення SAPERROR");
        artCaption.Text=T("SAPERROR  /  Analog horror puzzle","SAPERROR  /  Атмосферна головоломка");
        languageLabel.Text=T("Language","Мова"); pathLabel.Text=T("Installation folder:","Папка встановлення:");
        browse.Text=T("Browse...","Огляд..."); shortcut.Text=T("Create desktop shortcut","Створити ярлик на робочому столі");
        launch.Text=T("Launch SAPERROR when finished","Запустити SAPERROR після встановлення");
        statusLabel.Text=T("Ready to install. Game files and uninstaller will be added to the selected folder.","Готово до встановлення. Файли гри та засіб видалення буде додано до вибраної папки.");
        install.Text=T("Install","Встановити"); cancel.Text=T("Cancel","Скасувати");
    }
    void SetProgress(int value){ progress.Value=value; percent.Text=value+"%"; }
    void SetBusy(bool value){ busy=value; path.Enabled=!value; browse.Enabled=!value; shortcut.Enabled=!value; language.Enabled=!value; launch.Enabled=!value; install.Enabled=!value; cancel.Enabled=!value; }
    async Task InstallGame(){
        string dir;
        try{
            if(String.IsNullOrWhiteSpace(path.Text)||!Path.IsPathRooted(path.Text)||path.Text.IndexOf('"')>=0)throw new ArgumentException();
            dir=Path.GetFullPath(path.Text.Trim()).TrimEnd(Path.DirectorySeparatorChar,Path.AltDirectorySeparatorChar);
            if(String.Equals(dir,Path.GetPathRoot(dir).TrimEnd('\\'),StringComparison.OrdinalIgnoreCase))throw new ArgumentException();
            if(Directory.Exists(dir)&&Directory.GetFileSystemEntries(dir).Length>0&&!(File.Exists(Path.Combine(dir,"SAPERROR.exe"))&&File.Exists(Path.Combine(dir,"unins000.exe")))){
                MessageBox.Show(this,T("Choose an empty folder or an existing SAPERROR installation.","Оберіть порожню папку або наявне встановлення SAPERROR."),Text); return;
            }
        }catch{MessageBox.Show(this,T("Select a valid installation folder.","Оберіть коректну папку встановлення."),Text);return;}
        path.Text=dir;SetBusy(true);SetProgress(0);
        tempDir=Path.Combine(Path.GetTempPath(),"SAPERROR-setup-"+Guid.NewGuid().ToString("N"));
        progressPath=Path.Combine(tempDir,"progress.txt");
        string backend=Path.Combine(tempDir,"payload.exe");
        string args="/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /LANG="+(Ukrainian?"ukrainian":"english")+" /DIR=\""+dir+"\" /PROGRESSFILE=\""+progressPath+"\" /TASKS=\""+(shortcut.Checked?"desktopicon":"")+"\"";
        statusLabel.Text=T("Installing game files...","Встановлення файлів гри...");timer.Start();
        try{
            int code=await Task.Run(delegate{
                Directory.CreateDirectory(tempDir);
                using(var source=Resource("setup.payload"))using(var target=File.Create(backend))source.CopyTo(target);
                using(var process=Process.Start(new ProcessStartInfo(backend,args){UseShellExecute=false,CreateNoWindow=true})){process.WaitForExit();return process.ExitCode;}
            });
            if(code!=0||!File.Exists(Path.Combine(dir,"SAPERROR.exe"))||!File.Exists(Path.Combine(dir,"SAPERROR.pck")))throw new InvalidOperationException("Setup exit code: "+code);
            done=true;SetProgress(100);statusLabel.Text=T("Installation complete. SAPERROR is ready.","Встановлення завершено. SAPERROR готовий.");install.Text=T("Finish","Завершити");
        }catch(Exception ex){statusLabel.Text=T("Installation failed. Check the folder and try again.","Не вдалося встановити. Перевірте папку та спробуйте знову.");MessageBox.Show(this,ex.Message,Text,MessageBoxButtons.OK,MessageBoxIcon.Error);}
        finally{timer.Stop();SetBusy(false);if(done){path.Enabled=false;browse.Enabled=false;shortcut.Enabled=false;language.Enabled=false;cancel.Enabled=false;}try{Directory.Delete(tempDir,true);}catch(IOException){}catch(UnauthorizedAccessException){}}
    }
    protected override void Dispose(bool disposing){if(disposing){if(timer!=null)timer.Dispose();if(artImage!=null)artImage.Dispose();if(normal!=null)normal.Dispose();if(heading!=null)heading.Dispose();}base.Dispose(disposing);}
}
