package de.kreisquadratur.jEtherTeX;

import javax.swing.JFrame;
import javax.swing.JPanel;

import org.icepdf.ri.common.SwingController;
import org.icepdf.ri.common.SwingViewBuilder;

import com.trolltech.qt.core.*;
import com.trolltech.qt.gui.*;
import com.trolltech.qt.webkit.*;

public class Main extends QMainWindow {

	private final QWidget mainWidget;
	private final QHBoxLayout layout;
	private final QWebView browser;
	private final QLineEdit field;

	private SwingController controller;
	private SwingViewBuilder factory;
	private JPanel viewerComponentPanel;
	private JFrame applicationFrame;

	public Main() {
		this(null);
	}

	public Main(final QWidget parent) {
		super(parent);

		mainWidget = new QWidget();
		browser = new QWebView();
		field = new QLineEdit();

		// Toolbar...
		final QToolBar toolbar = addToolBar("Actions");
		toolbar.addWidget(field);
		toolbar.setFloatable(false);
		toolbar.setMovable(false);

		layout = new QHBoxLayout();
		layout.addStretch();
		layout.addWidget(browser);
		layout.addWidget(new QComponentHost(viewerComponentPanel));
		
		mainWidget.setLayout(layout);
		setCentralWidget(mainWidget);

		statusBar().show();

		setWindowTitle("jEtherTeX");
		setWindowIcon(new QIcon(
				"classpath:de/kreisquadratur/jEtherTeX/res/icon.png"));
		resize(800, 600);

		// Connections
		field.returnPressed.connect(this, "open()");

		browser.loadStarted.connect(this, "loadStarted()");
		browser.loadProgress.connect(this, "loadProgress(int)");
		browser.loadFinished.connect(this, "loadDone()");
		browser.urlChanged.connect(this, "urlChanged(QUrl)");

		// Set an initial loading page once its up and showing...
		QApplication.invokeLater(new Runnable() {
			public void run() {
				field.setText("http://" + "kreisquadratur" + ".etherpad.com/"
						+ "SA3" + "?fullScreen=1&sidebar=0");
				open();
			}
		});
		grabPadSourceCode();
	}

	void grabPadSourceCode() {
		QApplication.beep();
		QTimer.singleShot(5 * 1000, this, "grabPadSourceCode()");
	}

	public void urlChanged(final QUrl url) {
		field.setText(url.toString());
	}

	public void loadStarted() {
		statusBar().showMessage("Starting to load: " + field.text());
	}

	public void loadDone() {
		statusBar().showMessage("Loading done...");
	}

	public void loadProgress(final int x) {
		statusBar().showMessage("Loading: " + x + " %");
	}

	public void open() {
		String text = field.text();

		if (text.indexOf("://") < 0)
			text = "http://" + text;

		browser.load(new QUrl(text));
	}

	public void initPDFViewer() {
		// Needed becaue: "ICEpdf Open Source uses java.awt.Font when reading
		// font files for substitution. ICEpdf Open Source by default disables
		// java.awt.Font for reading embedded font files because a malformed
		// font file can crash the JVM." But we do need embedded fonts
		// especially for TeX documents.
		System.setProperty("org.icepdf.core.awtFontLoading", "true");

		final String filePath = "Test.pdf";

		// build a component controller
		controller = new SwingController();
		factory = new SwingViewBuilder(controller);
		viewerComponentPanel = factory.buildViewerPanel();
		applicationFrame = new JFrame();

		applicationFrame.getContentPane().add(viewerComponentPanel);

		// Now that the GUI is all in place, we can try openning a PDF
		controller.openDocument(filePath);
		controller.setPageViewMode(2, true);
		controller.setPageFitMode(3, true);
		controller.setToolBarVisible(false);
		controller.setUtilityPaneVisible(false);

		// show the component
		applicationFrame.pack();
		applicationFrame.setVisible(true);
	}

	@Override
	protected void closeEvent(final QCloseEvent event) {
		browser.loadProgress.disconnect(this);
		browser.loadFinished.disconnect(this);
	}

	public static void main(final String args[]) {
		QApplication.initialize(args);

		final Main window = new Main();
		window.show();
		window.initPDFViewer();

		QApplication.exec();
	}
}
