require File.expand_path('../../config/environment',  __FILE__)

module Dataservice

  INDEXES = %w{GLD IVV SPY QQQ}

  SNP500 = %w{A AA AAPL ABC ABT ACE ACN ADBE ADI ADM ADP ADSK AEE AEP
    AES AET AFL AGN AIG AIV AIZ AKAM ALL ALTR AMAT AMD AMGN AMP AMT
    AMZN AN ANF ANR AON APA APC APD APH APOL ARG ATI AVB AVP AVY AXP
    AZO BA BAC BAX BBBY BBT BBY BCR BDX BEAM BEN BFB BHI BIG BIIB BK
    BLK BLL BMC BMS BMY BRCM BRK.B BSX BTU BWA BXP C CA CAG CAH CAM
    CAT CB CBE CBG CBS CCE CCL CEG CELG CERN CF CFN CHK CHRW CI CINF
    CL CLF CLX CMA CMCSA CME CMG CMI CMS CNP CNX COF COG COH COL COP
    COST COV CPB CRM CSC CSCO CSX CTAS CTL CTSH CTXS CVC CVH CVS CVX D
    DD DE DELL DF DFS DGX DHI DHR DIS DISCA DLTR DNB DNR DO DOV DOW
    DPS DRI DTE DTV DUK DV DVA DVN EA EBAY ECL ED EFX EIX EL EMC EMN
    EMR EOG EP EQR EQT ESRX ETFC ETN ETR EW EXC EXPD EXPE F FAST FCX
    FDO FDX FE FFIV FHN FII FIS FISV FITB FLIR FLR FLS FMC FRX FSLR
    FTI FTR GAS GCI GD GE GILD GIS GLW GME GNW GOOG GPC GPS GR GS GT
    GWW HAL HAR HAS HBAN HCBK HCN HCP HD HES HIG HNZ HOG HON HOT HP
    HPQ HRB HRL HRS HSP HST HSY HUM IBM ICE IFF IGT INTC INTU IP IPG
    IR IRM ISRG ITW IVZ JBL JCI JCP JDSU JEC JNJ JNPR JOY JPM JWN K
    KEY KFT KIM KLAC KMB KMX KO KR KSS L LEG LEN LH LIFE LLL LLTC LLY
    LM LMT LNC LO LOW LSI LTD LUK LUV LXK M MA MAR MAS MAT MCD MCHP
    MCK MCO MDT MET MHP MHS MJN MKC MMC MMI MMM MO MOLX MON MOS MPC
    MRK MRO MS MSFT MSI MTB MU MUR MWV MYL NBL NBR NDAQ NE NEE NEM
    NFLX NFX NI NKE NOC NOV NRG NSC NTAP NTRS NU NUE NVDA NVLS NWL
    NWSA NYX OI OKE OMC ORCL ORLY OXY PAYX PBCT PBI PCAR PCG PCL PCLN
    PCP PCS PDCO PEG PEP PFE PFG PG PGN PGR PH PHM PKI PLD PLL PM PNC
    PNW POM PPG PPL PRGO PRU PSA PWR PX PXD QCOM QEP R RAI RDC RF RHI
    RHT RL ROK ROP ROST RRC RRD RSG RTN S SAI SBUX SCG SCHW SE SEE
    SHLD SHW SIAL SJM SLB SLE SLM SNA SNDK SNI SO SPG SPLS SRCL SRE
    STI STJ STT STZ SUN SVU SWK SWN SWY SYK SYMC SYY T TAP TDC TE TEG
    TEL TER TGT THC TIE TIF TJX TMK TMO TRIP TROW TRV TSN TSO TSS TWC
    TWX TXN TXT TYC UNH UNM UNP UPS URBN USB UTX V VAR VFC VIAB VLO
    VMC VNO VRSN VTR VZ WAG WAT WDC WEC WFC WFM WHR WIN WLP WM WMB WMT
    WPI WPO WPX WU WY WYN WYNN X XEL XL XLNX XOM XRAY XRX XYL YHOO YUM
    ZION ZMH}

  class Update
    
    def main

      logger.info("App Started")
      tickers = []
      tickers.concat(INDEXES)
      tickers.concat(SNP500)

      # Ensure that all the tickers exist
      tickers.each do |ticker|
        if (!Ticker::Exists(ticker))
          logger.info("Creating Ticker in DB "+
                      "ticker=[#{ticker}]")
          # Create it in the DB
          ActiveRecord::Base.transaction do
            t1 = Ticker.new()
            t1.name = ticker
            t1.ticker_type = :stock
            t1.status = :active
            t1.save()
          end
        end
      end

      
      # grep -i "No option data" production.log | perl -e 'while(<>) { $_ =~ /ticker=\[(\w+)\]/; print $1."\n" }'|sort|uniq
      #  BAC|BBY|BIG|C|CEG|GS|HAS|JPM|MS
      
      # Update the Stock's Option Data First
      tickers.each do |ticker|
        # MHS is from NYSE or INDEXDJX:MHS
        next if ticker.match(/BAC|BBY|BIG|C|CEG|GS|HAS|JPM|MS|NWL|MHS|WPO/)
        ActiveRecord::Base.transaction do
          Option::Update(ticker)
        end
      end
      
      # Update the Stock Data
      tickers.each do |ticker|
        next if ticker.match(/BAC|BBY|BIG|C|CEG|GS|HAS|JPM|MS|NWL|MHS|WPO/)
        ActiveRecord::Base.transaction do
          Stock::Update(ticker)
        end
      end

    end
    
    def logger
      return Rails.logger
    end
    
  end

u = Update.new()
u.main()
end




