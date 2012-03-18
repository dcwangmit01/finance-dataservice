require File.expand_path('../../config/environment',  __FILE__)

module Dataservice

  SNP500 = %w{AKAM}

  SNP500_1 = %w{MMM ACE ABT ANF ACN ADBE AMD AES AET AFL A GAS APD ARG
    AKAM AA ATI AGN ALL ALTR MO AMZN AEE AEP AXP AIG AMT AMP ABC AMGN
    APH APC ADI AON APA AIV APOL AAPL AMAT ADM AIZ T ADSK ADP AN AZO
    AVB AVY AVP BHI BLL BAC BK BCR BAX BBT BEAM BDX BBBY BMS BRK BBY
    BIG BIIB BLK HRB BMC BA BWA BXP BSX BMY BRCM BFB CHRW CA CVC COG
    CAM CPB COF CAH CFN KMX CCL CAT CBG CBS CELG CNP CTL CERN CF SCHW
    CHK CVX CB CI CINF CTAS CSCO C CTXS CLF CLX CME CMS COH KO CCE
    CTSH CL CMCSA CMA CSC CAG COP CNX ED STZ CEG GLW COST CVH COV CSX
    CMI CVS DHI DHR DRI DVA DF DE DELL DNR XRAY DVN DV DO DTV DFS
    DISCA DLTR D RRD DOV DOW DPS DTE DD DUK DNB ETFC EMN ETN EBAY ECL
    EIX EW EP EA EMC EMR ETR EOG EQT EFX EQR EL EXC EXPE EXPD ESRX XOM
    FFIV FDO FAST FII FDX FIS FITB FHN FSLR FE FISV FLIR FLS FLR FMC
    FTI F FRX BEN FCX FTR GME GCI GPS GD GE GIS GPC GNW GILD GS GR GT
    GOOG GWW HAL HOG HAR HRS HIG HAS HCP HCN HNZ HP HES HPQ HD HON HRL
    HSP HST HCBK HUM HBAN ITW TEG INTC ICE IBM IFF IGT IP IPG INTU
    ISRG IVZ IRM XYL JBL JEC CBE JDSU JNJ JCI JOY JPM JNPR K KEY KMB
    KIM KLAC KSS KFT KR LLL LH LM LEG LEN LUK LXK LIFE LLY LTD LNC
    LLTC LMT L LO LOW LSI MTB M MRO MPC MAR MMC MAS ANR MA MAT MKC MCD
    MHP MCK MJN MWV MHS MDT MRK MET PCS MCHP MU MSFT MOLX TAP MON MCO
    MS MOS MMI MSI MUR MYL NBR NDAQ NOV NTAP NFLX NWL NFX NEM NWSA NEE
    NKE NI NE NBL JWN NSC NTRS NOC NU CMG NVLS NRG NUE NVDA NYX ORLY
    OXY OMC OKE ORCL OI PCAR IR PLL PH PDCO PAYX BTU JCP PBCT POM PEP
    PKI PRGO PFE PCG PM PNW PXD PBI PCL PNC RL PPG PPL PX PCP PCLN PFG
    PG PGN PGR PLD PRU PEG PSA PHM QEP PWR QCOM DGX RRC RTN RHT RF RSG
    RAI RHI ROK COL ROP ROST RDC R SWY SAI CRM SNDK SLE SCG SLB SNI
    SEE SHLD SRE SHW SIAL SPG SLM SJM SNA SO LUV SWN SE S STJ SWK SPLS
    SBUX HOT STT SRCL SYK SUN STI SVU SYMC SYY TROW TGT TEL TE THC TDC
    TER TSO TXN TXT HSY TRV TMO TIF TWX TWC TIE TJX TMK TSS TRIP TSN
    TYC USB UNP UNH UPS X UTX UNM URBN VFC VLO VAR VTR VRSN VZ VIAB V
    VNO VMC WMT WAG DIS WPO WM WAT WPI WLP WFC WDC WU WY WHR WFM WMB
    WIN WEC WPX WYN WYNN XEL XRX XLNX XL YHOO YUM ZMH ZION}

  class Update
    
    def main

      # Ensure that all the tickers exist
      SNP500.each do |ticker|
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

      # Update the Stock Data
      SNP500.each do |ticker|
        logger.info(ticker.class)

        ActiveRecord::Base.transaction do
          Stock::Update(ticker)
        end

        expirations = Option::GetExpirations(ticker)
        logger.info(expirations.to_yaml())
        Option::Update(ticker)
        
      end

      # Update the Stock's Option Data


    end
    
    def logger
      return Rails.logger
    end
    
  end

u = Update.new()
u.main()
end



