package Goodscrapes;
use strict;
use warnings;
use 5.18.0;
use utf8;

###############################################################################

=pod

=encoding utf8

=head1 NAME

Goodscrapes - Simple Goodreads.com scraping helpers


=head1 VERSION

=over

=item * Updated: 2018-07-21

=item * Since: 2014-11-05

=back

=cut

our $VERSION = '1.90';  # X.XX version format required by Perl


=head1 COMPARED TO THE OFFICIAL API

=over

=item * focuses on analysing, not updating info on GR

=item * less limited, e.g., reading shelves and reviews of other members

=item * official API is slow too; API users are even second-class citizen

=item * theoretically this library is more likely to break, 
        but Goodreads progresses very very slowly: nothing
        actually broke since 2014 (I started this);
        actually their API seems to change more often than
        their web pages; they can and do disable API functions 
        without being noticed by the majority, but they cannot
        easily disable important webpages that we use too

=back


=head1 LIMITATIONS

=over

=item * slow: version with concurrent AnyEvent::HTTP requests was marginally 
        faster, so I sticked with simpler code; doesn't actually matter
        due to Amazon's and Goodreads' request throttling. You can only
        speed things up significantly with a pool of work-sharing computers 
        and unique IP addresses...

=item * just text pattern matching, no ECMAScript execution and DOM parsing
        (so far sufficient and faster)

=back


=head1 AUTHOR

https://github.com/andre-st/


=cut

###############################################################################


use base 'Exporter';
our @EXPORT = qw( 
		require_good_userid
		require_good_shelfname
		is_bad_profile
		set_good_cookie 
		set_good_cookie_file 
		set_good_cache 
		amz_book_html 
		query_good_books 
		query_good_user
		query_good_author_books
		query_similar_authors
		eta_query_good_reviews
		query_good_reviews
		query_good_followees );


use HTML::Entities;
use WWW::Curl::Easy;
use Cache::Cache qw( $EXPIRES_NEVER $EXPIRES_NOW );
use Cache::FileCache;
use Time::Piece;  # Core module, no extra install


our $USERAGENT    = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13';
our $COOKIEPATH   = '.cookie';
our $NOUSERIMGURL = 'https://s.gr-assets.com/assets/nophoto/user/u_50x66-632230dc9882b4352d753eedf9396530.png';
our $SORTNEW      = 'newest';
our $SORTOLD      = 'oldest';
our $EARLIEST     = Time::Piece->strptime( '1970-01-01', '%Y-%m-%d' );
our @REVSRCHDICT  = qw(
		ing ion tio ati ent ter the ate con men ess tra ine and nce res pro per cti ect for tic sth rat sta ste ica ive ver est tin str tor one ist all int com rea
		ant ite age lin ble ran rin cal der nte anc ity ure oun eri ain ers ear nal iti her act ted era tur sti ons ort art lan lat man ell igh tri nes ial ous gra
		ast nti enc ack ice ide par cha lit ric min ass ill cat red pla und ree ard eat pre dis out ove ont ght our din ian tal mat eme ang sio tiv tat che ina nta
		hea ona sto ome abl ali ral ake nde lea ead ssi tan nge low eas rac ntr mon ind tte rit car ore den lar rou tro hin ili ten pri wor ria are end rec ner ren
		nin har olo ary ele lle ish chi ave tre han ari unt ith kin sin ula ere ail ope lic wit ser ost les ins spe fic omp ies nat ase orm ern ace lac ood cre ene
		sur ust gen ple col tai pin sit ces ini ens ock mar por ans ori ato ris hor rop cou eve rti nit use tle tar uct oli air ndi mer pos cle ber erm ese ron ani
		sis tem log cor ise ord ler rai ath gre rma ime ire rom ile oll ert met bil off tch edi ara win lli oni ach led can las att old sho own llo pen cia omm arr
		ade ose duc thr eco cen ros ory inc shi nic ana cul ale war ora son sel osi ult acc mor ame dia roc rad eed rie lec ita esi tru app fer rap row ven ger ark
		ici ond eli ret cke ton rch oth mal spo ick ete ong tes owe lly lis tim nst pec fin cro bra erv cto nsi rel ote rot wer ura rol sse adi ien qua hol sea let
		eal oss que fac val eti ole gin tho vel ane nis ign ual sha ork cur qui uni bla uri gro dit tom ker thi mou pol rge bre lla aci oma iss mic she ram uti tit
		len yst sen rem fro cho tis lig iat oin ifi hit oot pan isi nch equ eta ape dge nts ket pat hro ffi rre sal hou nne mis eni ery rde ban roo err mpl whi cla
		ami ean ode ffe pho pti ded rus des ier spi bac ogr ras sec cer mil bro eci sca bar ima tab amp net loc flo cap ala tec arc wat arg atu unc ctu tia ism exp
		nci emi ivi vic pea bri ppe ush eet mit los dic usi lon lue bea orn clo hav rse cie scr ero cas omi mpe sid nda rth rro sig cra imp abi lia emo ann ett rog
		ech oti nse emp med ute rep rio fil loo arm dat rig ook ngl eel lay tie fla ize pli itt oce ash mot dro dow inf eak aph ool bal ank rce oph sor sol fis elf
		mag nto rid ono asi roa sed fir ttl ema rod ruc pha een erc hic urn hes pot cri ses ild ott uit ull mbe nar spa pac eck ict tel ept get hal reg ugh put ela
		mos not dea sys bli del mea eng rag oto rim ncy hip ned lem sup oad mpa set cin sub onc lie rip riv sco woo cit ext ume hil avi bel ata tee alt gle uth non
		ium abo lif eth phi ful try eep evi isc cel eac lor bor bus fre nan sch bas lou etr dra ors dec odu eld iza bat mme nia vin dri bit way aut iou ves ped dle
		rri til top hel vis arb nsu ppl cut oil nve stu itu erg ref sou blo hee ink rke pon lum hon ece ump atc cep lim mod bou his pit sat umb ngu tea hoo rte mas
		cop but phy ssu pic ife rna ubl bon ngs sic ike ola olu oat boo ngi poi ctr iso gat tak utt rvi ogi ily lde wee ray nom lam dar gar rni rdi eam fie mak mul
		erf ogy add eig nds bin dep tag imi tac oci san pul pai rve urs tme hai irc uck oug rmi ics ama orc cco mac fra cus fun ars fec ecu lti gic sla def ked wel
		ced ena sil vol tif lab hed ito nor oca mus aff vat day hig ndu goo cid mpo sia pet cli leg mai mmo elo upp edu soc hem hre ndo urr pal hot lev cce dre ipe
		ney sma lot ino ota ski pas ule bir pur lve alu zat mes tti nec fly jec iel arl liv dev liz ird egi gan cos ein rib wal iva eye bur rob foo eer isa vio lut
		adv rne orr fri eav nag loa edg cte epa blu hat pow wea oor vit uar sso als bul amm ano emb dan dem gua uro ega onf plo eno ldi fee nni yel urc lid rab sul
		ied ges gla omb rry oup lop aft ida mun dio cis nth sum iff law sna rum run eff siv idi rta oom too die iol rcu rev lus esc cip nco mmi efe yme opp tua alo
		nct uat rov ysi num ede syn tud uil hen sci icu coa rso inv ndr phe oke yin aga van obi ham rra itc asu rav any opi uff apa nee rsi ype pay fle squ chn nos
		gal raw uen heo ely oly rst sem amo hop ich lad urt flu nel bee exc ues toc tha lip oge onn hos odi amb ior gas tto boa dom ovi ged cir aus gol spr ibl ung
		omo efi now udi xpe aro has ppo eor agr gue nam sce cil mmu arn oid ssa gui aly onv fou pie pra rty ift rme isp org rew dus nfo vid ibi inn raf owl mel mov
		eaf ois gri uto nsp isk rga gem atr oar ico key fit iga rof orp nme rds ipp osp alk hri pir whe awa ody div nio lai two nea urg esp fal gna rei sli nut vil
		dam swi rmo sts nou dou kno lag dir api gul ila opo agi ige hom igi ipl erp coo ety gai ril pee yer fai mol ecr nol cum don epo pil gis icl dif hyp agn epi
		iqu mem epe var req sle gon egr doc cab mma ava opt oro lte neu erb shr avo lau beh obl opl new tum ask glo lov ude aki fam ago ror spl mpt irs scu aso ndl
		yea som cru giv eha wil tta clu fli tig lys riz ben cov inu bio nif chr ocu cam ibr oub pme ycl tou iri iet gne ncr cki imm nig rts uir its ckl gio hum lik
		lee geo iro oon rif bot hyd fen det typ och cyc ado erl ppr see ais pub rer ppi eur ibu nim eph eso pap rgi uce kee was uch uid fol vir iod irt omy mid hur
		dul tax aul bui ait oxi irr bed icr sty upe nai ved ods ilt cot arp vie bod ydr axi tol thy tow alc uss oco lio tas tub opa zin nak deb rly dde osc bol ube
		gam rci iab dal kle swe anu lta sib hie ira alm ubs far bab ddi pop fig aye orl rey aug mpi hod bet plu abb cks ada rbo sph mpr het cem hap ibe gia rui nfl
		aca chu nen uis rli smo ltu nso wri box abs rar rva stl une nke eek rsh mpu tly aid epr ilk mbi enn ngt acr lex niz pel exa idg nsa iag nfe uma eop fus tip
		nfi elt alv smi rbi ken lls oul tut oof eva bst una cta unn nna zon lyc ply apo tun bia eca rpo gly ets loy afe ebr stm exi aco mbl ipa tap esh occ asp uns
		urp ofi rld tog imu ege fes rki cup pig dog pid xtr fur ilo sag dee igu egu olt coc efo dur ccu eon gge iar lse uca bje cei sac uta fte rfa rub oop uli ees
		ddl bbl itr rak uan nga oos dmi gli uag hir ony rba umm sus tam vem hru nem rtu aym llu dru fat asc gea teg wom gth ilm tus umi aba ntu rul adm aud oic cts
		git bly ief wed pou ske hni ntl eto mia nas rms saf sun xte dor voi dly ipt rgy fea gni icy uin cod noc dig cau obs oba urv doo cio nki ynd hun jus zed usc
		agg alf hts lob urf hys poo nvi fru hte rpe eem nsf cif fet exe tos ova pip bru diu hec hab sue els suc mbo rfo sam joi oft zar moo lun apt dne fav hno gur
		lap udg ymp zer ady osa via tyl pto wan etl hag oac dve lth acu abe efu iew opy pte rbl wis fas ubb dol ley mbr noi neg bag sly gel how bic wne wre yca yle
		bbe psy tne lib imb oal obe slo umo fan fib rik swa wav ays odo uls arf sno urb you eou lep nab ids kni vor mba iec ouc enu vou efl edl ops tot sof nap vac
		ych idd ehi sne ury tid oct rle rsa pta rup adj etw rwa dua kil irl sym bad rug dwa vet ecl eec opm tex cui chl egg tei luc sex ypo usa wir hid igr nua wle
		ats eol asa eap ebe gir wes irm nuc wei bes lom pis cry pse ngo opu rtr wag jac tep cyt aim sim hio neo reb coi oso mum dry sui cko mph nop sme eda ego twi
		unk nac owi tir hei bow lug rpl oan oas rbe rks sop abr erd lef lub rau aps idu wid bun lav bso scl cci dva lph xpo aun evo cad lur epl ucl siz ulo roj atm
		opr roi ifo oje nsh mur upt eum hoe usl eba etu job ixe alp sep env fix hob tiz acy dim aem leo orb owa uge niv hoc kit ocy rpr uga ias yth gag sar aur oki
		pes esu tib tyr yli haw rtm pus nnu twe yna deg erw ngr seq hme ips nus sab oxy bse pum xed eft nsc ucc cav utu etc kne eut ewa apy pag fau ilv auc azi kes
		uty agu sau uld onm oud reh xic dju syc upl nno xch iot big hib ald gno vas cqu ipm eho epu eag ruf sfe xam urd leu awk ebt leb liq eab acq bom gun mig mix
		peo bec yed ify ewe uel had rph iam rtl ulp inh inj dli gor ugg asm eau ils yan eit gus niu ncl saw lmo rco nov hae iry hau rok dos map uts edo mec otr lil
		jun sav sua uic veh hia lym orw nur ews wai bis aby obj pun spu eds ulf oes utr yto osu who awn eiv alg aze ido ots ows iev rrh ofe mut fel lco mir lpi cea
		ddr mad mom hyl ios nie rto hly usp cka got ltr nsm cog riu aig dil poc uou ogn dut seu lty xpl iog rhe nju tli xid imo oms onk gov dvi hlo pia slu ams gme
		aer eru ths asy iny iop bug jur rut owd ptu toi adl apl vot igg ipi nad reo dai sky thu hra rfe rfl uip umn phr pyr nip nod uer yro yte ggl lfi olv oda sif
		xim xis hif isl nul toe vei kel udd dex nef goa yri ads ewo jud pad fid izi hoi owt abu eil ems chy onu niq sev arv oga tet yti aya dip ibb thm nca nog uci
		unf max ebo fem hog iac sug iom lyi eis yra ldr nbi quo oya wha dov xce sai ajo ocr nqu raz upi voc ewi xer cof obb cow jor mok mog uor acl hti kag usn moc
		udy elv nha rgo unb rox ufo bud ilu twa wth doi pio lyt oym igo loi rue bbi due fed yla ehe nuf tma itl yar erh mee rca rno yre ubi lme sie rud buc dop emu
		taf maj hle nre gfi iph avy chm hus odd ubj bid jou pod rha ulu isu exh tul ivo coh nfa dyn ndw soi tox haf lne nty ggi unr ghe ffl tla utc mbu mob muc glu
		ogu adr pep rnm shu dum lei nny beg boy cet edd ylo civ hut vey buy odp xin aza gob rys vag efr ols swo ums url jum rcl gum nob rda hyt dpe ipo nks uco yes
		exu rcr stn eez sod suf coe ngf nei yal yon agl rho eev nex tod ayi uad epp utp ynt ufa efa lax oye unp tty deo dst ffo uai zen usk dwe toa eke gau nfr uet
		luo ndy dys rru tsh vai azo kis lcu nav dag dap elm oak cca enz ius izo buf nsl nli rfi sad vul edn aty gou bum shm elp upr lwa nil adu edr nae dot ebi mst
		nle ryo thl rgu haz oby osy eud gil olf ryi cky lsi nvo yco aqu obo foc eps upo ebu eze xil gmy him inl esa oho rla tnu ims pne tpu psi veg uba uno das dhe
		eus hwa rlo did rns lel udo upa mud myo ogg lod nsw rix cyl urk ffa kid xpr iru nue rdo cuc dab hym utl gie uot lva rmu vip wax hep pyg rtn sap ttr fue ppa
		pru ckn dwi ppy teo ygm tuf wde xpa aka dib ulb wra wif cac iki kan yll ghi ghl lud cak gap inp fox onl tob xec cee zzl cub kir mam nly oit rwo gec ubt laz
		tay bsc cys nid eir lfa lua osm ncu uee bos ioc rpi ssm awe gho hbo ogo rfu rmy roe sot ssl lki oty 
		); # N=2443, most frequent english n-grams first (or should randomize with List::shuffle?)


our @REVSRCHDICT_OPTIMIZED = qw(
		3 4 5

		let wit ing put ten met ass ini bit lit men job get rat cut mix our
		are owe win all con hit the use pre ran ist ate you art per era ton
		her end ter lot old one and low fit was fan too ill dec add tho pay
		row tra ver act mad sat awe nor ive can new car had ish for tan pro
		she lea ice not age two cat got off far lay wee tea try day kid est
		sin way red etc par sit ser com cos led sum fed see own son mum por
		out via saw fun rid ear ink now eat his hes mid but eye han ugh ron
		bar who ask dit yea fav how pop bad due bug don sci sad set ame hot
		man dry ago air lie fly run did bat law bed tip leg cry has mom tie
		bag yes boy top ese gem him bus map war fix amo odd wat its app tal
		owl mil dog las pun arc nth che buy egg fat der dia ler mal pig key
		tom mis pet sun beg big alt hid que dat any box eso sex del rip nos
		sea sky ama leo hog und ban sus lee aug mon mas til den ans hut yer
		aka itu bet pen dig net nov asi boa ele los eve lei dio una vas tak
		gap ale ont fue min tag les bow non hal sem imo rob uni sue ein ook
		dan aun boo fin tem qui ins arm nel ora ref tim ani hop pan sam chi
		hat ada lil esa nut poi inc sub api pat aid umm bin lad def uno doo
		oli oct nit mes vol lap bir din pra pie tha mit dis sis uit ect sur
		cap ben mai int ali ilk pub max dos mia eva dal raw flu wer ile des
		gue dar pot bon elf har ven dip log ide apa mud wel bom woo ray cup
		toe ant aim gar ero	
		
		    ion tio ati ent                     ess     ine     nce res    
		    cti         tic sth     sta ste ica             tin str tor    
		                rea     ite     lin ble     rin cal     nte anc ity
		ure oun eri ain ers     nal iti         ted     tur sti ons ort    
		lan lat     ell igh tri nes ial ous gra
		
		); # N=???, most frequent english trigrams tested against Harry Potter
		   # reviews: each led to 10-30 unique(!) hits, best first.
		   # Appended most frequent english trigrams which are not
		   # already present in the Harry Potter set.
		   # Works better with a larger set of available reviews.
		   # Randomization yield no improvements (rather opposite).


our $_cookie    = undef;
our $_cache_age = $EXPIRES_NOW;  # see set_good_cache()
our $_cache     = new Cache::FileCache({ namespace => 'Goodscrapes' });



=head1 DATA STRUCTURES

=head2 Note

=over

=item * never cast 'id' to int or use %d format string, despite digits only, 
        compare as strings

=item * don't expect all attributes set (C<undef>), this depends on context

=back


=head2 %book

=over

=item * id          => C<string>

=item * title       => C<string>

=item * isbn        => C<string>

=item * num_ratings => C<int>

=item * user_rating => C<int>

=item * url         => C<string>

=item * img_url     => C<string>

=item * author      => C<L<%user|"%user">>

=back


=head2 %user

=over

=item * id         => C<string>

=item * name       => C<string>

=item * age        => C<int> (not supported yet)

=item * is_friend  => C<bool>

=item * is_author  => C<bool>

=item * is_female  => C<bool> (not supported yet)

=item * is_private => C<bool> (not supported yet)

=item * url        => C<string> URL to the user's profile page

=item * works_url  => C<string> URL to the author's distinct works (is_author == 1)

=item * img_url    => C<string>

=back


=head2 %review

=over

=item * id          => C<string>

=item * user        => C<L<%user|"%user">>

=item * book_id     => C<string>

=item * rating      => C<int> 
                       with 0 meaning no rating, "added" or "marked it as abandoned" 
                       or something similar

=item * rating_str  => C<string> 
                       represention of rating, e.g., 3/5 as S<"[***  ]"> or S<"[TTT  ]"> 
                       if there's additional text

=item * text        => C<string>

=item * date        => C<Time::Piece>

=item * review_url  => C<string>

=back

=cut




=head1 PUBLIC SUBROUTINES



=head2 C<string> require_good_userid( I<$user_id_to_verify> )

=over

=item * returns a sanitized, valid Goodreads user id or kills 
        the current process with an error message

=back

=cut

sub require_good_userid
{
	my $uid = shift || '';
	return $1 if $uid =~ /(\d+)/ 
		or die "[FATAL] Invalid Goodreads user ID \"$uid\"";
}




=head2 C<string> require_good_shelfname( I<$name_to_verify> )

=over

=item * returns the given shelf name if valid 

=item * returns a shelf which includes all books if no name given

=item * kills the current process with an error message if name is malformed

=back

=cut

sub require_good_shelfname
{
	my $name = shift || '%23ALL%23';
	die "[FATAL] Invalid Goodreads shelf name \"$name\". Look at your shelf URLs."
		if $name =~ /[^%a-zA-Z0-9_\-]/;
	
	return $name;
}




=head2 C<bool> is_bad_profile( I<$user_or_author_id> )

=over

=item * returns true if blacklisted users or author who dirties and slows down any analysis

=item * "NOT A BOOK" author (3.000+ books), "Anonymous" author (10.000 books),
        non-orgs with 100.000+ books (probably bots or analytics accounts) etc

=back

=cut

sub is_bad_profile
{
	my $uid = shift;
	# smartmatch or List::MoreUtils::any would be better but
	# former is experimental and latter not core module :|
	return grep { $_ eq $uid } [
		            # Unquestionably useless:
		'1000834',  #    3.000 books   NOT A BOOK author
		'5158478',  #   10.000 books   Anonymous
		            #  
		            # Questionable worth vs time:
		'2938140',  #    2.218 books   Jacob Grimm (Grimm brothers)
		'128382',   #    2.802 books   Leo Tolstoy
		'173327'    #      365 books   Germany (Gov?)
	];
}




=head2 C<void> set_good_cookie( I<$cookie_content_str> )

=over

=item * some Goodreads.com pages are only accessible by authenticated members

=item * copy-paste cookie from Chrome's DevTools network-view

=back

=cut

sub set_good_cookie
{
	$_cookie = shift;
}




=head2 C<void> set_good_cookie_file( I<$path_to_cookie_file = '.cookie'> )

=cut

sub set_good_cookie_file
{
	my $path = shift || $COOKIEPATH;
	local $/=undef;
	open my $fh, "<", $path or die
			"[FATAL] Please save a Goodreads cookie to \"$path\". ".
			"Copy the cookie, for example, from Chrome's DevTools Network-view: ".
			"https://www.youtube.com/watch?v=o_CYdZBPDCg";
	
	binmode $fh;
	set_good_cookie( <$fh> );
	close $fh;
}




=head2 C<bool> test_good_cookie()

=over

=item * not supported at the moment

=back

=cut

sub test_good_cookie()
{
	# TODO: check against a page that needs sign-in
	# TODO: call in set_good_cookie() or by the lib-user separately?
	
	warn "[WARN] Not yet implemented: test_good_cookie()";
	return 1;
}




=head2 C<void> set_good_cache( I<$number, $unit = 'days'> )

=over

=item * scraping Goodreads.com is a very slow process

=item * scraped documents can be cached if you don't need them "fresh"

=item * e.g., during development time

=item * e.g., during long running sessions (cheap recovery on crash, power blackout or pauses)

=item * e.g., when experimenting with parameters

=item * unit can be C<"minutes">, C<"hours">, C<"days">

=back

=cut

sub set_good_cache
{
	my $number  = shift;
	my $unit    = shift || 'days';
	$_cache_age = "${number} ${unit}";
}




=head2 C<(L<%book|"%book">,...)> query_good_books( I<$user_id, $shelf_name> )

=cut

sub query_good_books
{
	my $uid   = shift;
	my $shelf = shift;
	my $page  = 1; 
	my @books;
	
	while( _extract_books( \@books, _html( _shelf_url( $uid, $shelf, $page++ ) ) ) ) {};
	
	return @books;
}




=head2 C<int> query_good_author_books( I<$books_array_ref, $author_id> )

=over

=item * I<$books_array_ref>: C<(L<%book|"%book">,...)>

=item * returns the number of books of the given author

=back

=cut

sub query_good_author_books
{
	my $books_ref = shift;
	my $uid       = shift;
	my $numbefore = scalar @$books_ref;
	my $page = 1;
	
	while( _extract_author_books( $books_ref, _html( _author_books_url( $uid, $page++ ) ) ) ) {};
	
	return scalar @$books_ref - $numbefore;
}




=head2 C<(L<%review|"%review">,...)> query_good_reviews(
	I<{ book => C<L<%book|"%book">>, since => undef, stalltime => undef, on_progress => undef, use_dict = 1 }> )

=over

=item * loads ratings (no text), reviews (text), "to-read", "added" etc;
        you can filter yourself afterwards

=item * optional I<since> argument of type C<Time::Piece>

=item * optional I<use_dict>: try to find additional reviews by using the 
        text-search function provided by Goodreads.com;
        useful for sentiment analysis or non-books-overarching analysis 
        of members (likely too random otherwise)

=item * optional I<stalltime> is the number of seconds to wait for a win 
        when trying to find additional reviews, aborts if exceeded

=item * if I<stalltime> is set to 0 (fastest) then the latest
        reviews only are considered (max. 300 reviews)

=item * set I<stalltime> to a very large value if you want the search take 
        as long as it needs, which is okay for a project on a single book,
        but would take too long for 1000 books

=item * I<stalltime> is not exact

=item * optional I<on_progress> callback function is called with a string 
        argument, which contains the number of currently loaded reviews or 
        other characters (use %5s in format strings)

=back

=cut

sub query_good_reviews
{
	my %result;
	my (%args)    = @_;
	my $book      = $args{book} or die "[FATAL] Argument `book` expected.";
	my $bid       = $book->{id};
	my $limit     = defined $book->{num_ratings} ? $book->{num_ratings} : 5000000;
	my $stalltime = $args{stalltime}   || ( $args{since} ? 0 : 1*60 );
	my $use_dict  = $args{use_dict}    || 1;
	my $progfn    = $args{on_progress} || sub {};
	my $since     = $args{since}       || $EARLIEST;
	   $since     = Time::Piece->strptime( $since->ymd, '%Y-%m-%d' );  # Nullified time in GR too
	
	$progfn->( 0 );  # Initializes progress display
	
	
	# Goodreads reviews filter gets us dissimilar(!) subsets which are merged here (N<5400):
	# Zero stall-time means 'fast result': Newest only, any rating (see recentrated.pl)
	my @rateargs = $stalltime == 0 ? ( undef    ) : ( undef, 1..5               );
	my @sortargs = $stalltime == 0 ? ( $SORTNEW ) : ( undef, $SORTNEW, $SORTOLD );
	for my $r (@rateargs)
	{
		for my $s (@sortargs)
		{
			my $page = 1;
			while( _extract_revs( \%result, $progfn, $since, _html( _revs_url( $bid, $s, $r, undef, $page++ ) ) ) ) {};
			
			# "to-read", "added" have to be loaded before the rated/reviews
			# (undef in both argument-lists first) - otherwise we finish
			# too early since $limit equals the number of *ratings* only.
			# Ugly code but correct in theory:
			my $numrated = scalar( grep { defined $_->{rating} } values %result ); 
			goto DONE if $numrated >= $limit;
		}
	}
	
	
	# Dict-search works well many ratings but poorly with few (waste of time).
	# A high stall-time, however, indicates that someone really wants to know:
	
	goto DONE if $limit < 3000 && $stalltime < 10*60;
	goto DONE if !$use_dict;
	
	my $t0 = time;   # Stuff above might already take 60s
	for my $word (@REVSRCHDICT_OPTIMIZED)
	{
		goto DONE if time-$t0 > $stalltime || scalar keys %result >= $limit;
		
		my $numbefore = scalar keys %result;
		
		_extract_revs( \%result, $progfn, $since, _html( _revs_url( $bid, undef, undef, $word ) ) );
		
		$t0 = time if scalar keys %result > $numbefore;  # Resets stall-timer
	}
	
DONE:

	return values %result;
}




=head2 C<(id =E<gt> L<%user|"%user">,...)> query_good_followees( I<$user_id> )

=over

=item * Precondition: set_good_cookie()

=item * returns friends AND followees

=back

=cut

sub query_good_followees
{
	my $uid = shift;
	my %result;
	my $page;

	$page = 1;
	while( _extract_followees( \%result, _html( _followees_url( $uid, $page++ ) ) ) ) {};
	
	$page = 1;
	while( _extract_friends( \%result, _html( _friends_url( $uid, $page++ ) ) ) ) {};
	
	return %result;
}




=head2 C<(L<%user|"%user">,...)> query_similar_authors( I<$author_id> )

=cut

sub query_similar_authors
{
	my $uid = shift;
	return _extract_similar_authors( $uid, _html( _similar_authors_url( $uid ) ) );
}




=head2 C<string> amz_book_html( I<L<%book|"%book">> )

=over

=item * HTML body of an Amazon article page

=back

=cut

sub amz_book_html
{
	return _html( _amz_url( shift ) );
}






=head1 PRIVATE SUBROUTINES



=head2 C<string> _amz_url( I<L<%book|"%book">> )

=over

=item * Requires at least {isbn=>string}

=back

=cut

sub _amz_url
{
	my $book = shift;
	return $book->{isbn} ? 'http://www.amazon.de/gp/product/' . $book->{isbn} : undef;
}




=head2 C<string> _shelf_url( I<$user_id, $shelf_name, $page_number = 1> )

=over

=item * URL for a page with a list of books (not all books)

=item * "&per_page=100" has no effect (GR actually loads 5x 20 books via JavaScript)

=item * "&print=true" not included, any advantages?

=item * "&view=table" puts I<all> book data in code, although invisible (display=none)

=item * "&sort=rating" is important for `friendrated.pl` with its book limit:
        Some users read 9000+ books and scraping would take forever. 
        We sort lower-rated books to the end and just scrape the first pages:
        Even those with 9000+ books haven't top-rated more than 2700 books.

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _shelf_url  
{
	my $uid   = shift;
	my $shelf = shift;
	my $page  = shift || 1;
	return "https://www.goodreads.com/review/list/${uid}?shelf=${shelf}&page=${page}&view=table&sort=rating&order=d";
}




=head2 C<string> _followees_url( I<$user_id, $page_number = 1> )

=over

=item * URL for a page with a list of the people $user is following

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _followees_url
{
	my $uid  = shift;
	my $page = shift || 1;
	return "https://www.goodreads.com/user/${uid}/following?page=${page}";
}




=head2 C<string> _friends_url( I<$user_id, $page_number = 1> )

=over

=item * URL for a page with a list of people befriended to C<$user_id>

=item * "&sort=date_added" (as opposed to 'last online') avoids 
        moving targets while reading page by page

=item * "&skip_mutual_friends=false" because we're not doing
        this just for me

=item * B<Warning:> changes to the URL structure will bust the file-cache

=back

=cut

sub _friends_url
{
	my $uid  = shift;
	my $page = shift || 1;
	return "https://www.goodreads.com/friend/user/${uid}?page=${page}&skip_mutual_friends=false&sort=date_added";
}




=head2 C<string> _book_url( I<$book_id> )

=cut

sub _book_url
{
	my $bid = shift;
	return "https://www.goodreads.com/book/show/${bid}";
}




=head2 C<string> _user_url( I<$user_id, $is_author = 0> )

=cut

sub _user_url
{
	my $uid    = shift;
	my $is_aut = shift || 0;
	return 'https://www.goodreads.com/'.( $is_aut ? 'author' : 'user' )."/show/${uid}";
}




=head2 C<string> _revs_url( I<$book_id, $str_sort_newest_oldest = undef, 
		$search_text = undef, $rating = undef, $page_number = 1> )

=over

=item * "&sort=newest" and "&sort=oldest" reduce the number of reviews for 
        some reason (also observable on the Goodreads website), 
        so only use if really needed (&sort=default)

=item * "&search_text=example", max 30 hits, invalidates sort order argument

=item * "&rating=5"

=item * the maximum of retrievable reviews is 300 (state 2018-06-22)

=item * seems less throttled, not true for text-search

=back

=cut

sub _revs_url
{
	my $bid  = shift;
	my $sort = shift || undef;
	my $rat  = shift || undef;
	my $text = shift || undef;
	my $page = shift || 1;
	return "https://www.goodreads.com/book/reviews/${bid}?"
		.( $sort && !$text ? "sort=${sort}&"        : '' )
		.( $text           ? "search_text=${text}&" : '' )
		.( $rat            ? "rating=${rat}&"       : '' )
		.( $text           ? "" : "page=${page}"         );
}




=head2 C<string> _rev_url( I<$review_id> )

=cut

sub _rev_url
{
	my $rid = shift;
	return "https://www.goodreads.com/review/show/${rid}";
}




=head2 C<string> _author_books_url( I<$user_id, $page_number = 1> )

=cut

sub _author_books_url
{
	my $uid  = shift;
	my $page = shift || 1;
	return "https://www.goodreads.com/author/list/${uid}?per_page=100&page=${page}";
}




=head2 C<string> _author_followings_url( I<$author_id, $page_number = 1> )

=cut

sub _author_followings_url
{
	my $uid  = shift;
	my $page = shift || 1;
	return "https://www.goodreads.com/author_followings?id=${uid}&page=${page}";
}




=head2 C<string> _similar_authors_url( I<$author_id> )

=over

=item * page number > N just returns same page, so no easy stop criteria;
        not sure, if there's more than page, though

=back

=cut

sub _similar_authors_url
{
	my $uid  = shift;
	return "https://www.goodreads.com/author/similar/${uid}";
}




=head2 C<bool> _extract_books( I<$result_array_ref, $shelf_tableview_html_str> )

=over

=item * I<$result_array_ref>: C<(L<%book|"%book">,...)>

=back

=cut

sub _extract_books
{
	my $books_ref = shift;
	my $html      = shift;
	my $ret       = 0;
	
	while( $html =~ /<tr id="review_\d+" class="bookalike review">(.*?)<\/tr>/gs ) # each book row
	{	
		my $row  = $1;
		my $id   = $1 if $row =~ /data-resource-id="([0-9]+)"/;
		my $isbn = $1 if $row =~ /<label>isbn<\/label><div class="value">\s*([0-9X\-]*)/;
		my $numr = $1 if $row =~ /<label>num ratings<\/label><div class="value">\s*([0-9]+)/;
		my $img  = $1 if $row =~ /<img [^>]* src="([^"]+)"/;
		my $auid = $1 if $row =~ /author\/show\/([0-9]+)/;
		my $aunm = $1 if $row =~ /author\/show\/[^>]+>([^<]+)/;
		   $aunm = decode_entities( $aunm );
		
		# Counts occurances; dont match "staticStars" (trailing s) or "staticStar p0"
		my $urat = () = $row =~ /staticStar p10/g;
		
		# Extracts title
		# + Removes HTML in "Title <span style="...">(Volume 35)</span>"
		# + Reduces "   " to " " and remove line breaks
		# + Replaces &quot; etc with " etc
		my $tit = $1 if $row =~ /<label>title<\/label><div class="value">\s*<a[^>]+>\s*(.*?)\s*<\/a>/s;
		   $tit =~ s/\<[^\>]+\>//g;
		   $tit =~ s/( {1,}|[\r\n])/ /g;  
		   $tit = decode_entities( $tit );
		
		push @$books_ref, { 
				id          => $id, 
				title       => $tit, 
				isbn        => $isbn, 
				author      => { 
					id         => $auid,
					name       => $aunm,
					url        => _user_url( $auid, 1 ),
					works_url  => _author_books_url( $auid ),
					img_url    => undef,
					is_autor   => 1,
					is_private => 0,
					is_female  => undef,
					is_friend  => undef
				},
				num_ratings => $numr, 
				user_rating => $urat, 
				url         => _book_url( $id ),
				img_url     => $img };
		
		$ret++;
	}
	return $ret;
}




=head2 C<bool> _extract_author_books( I<$result_array_ref, $html_str> )

=over

=item * I<$result_array_ref>: C<(L<%book|"%book">,...)> 

=back

=cut

sub _extract_author_books
{
	my $books_ref = shift;
	my $html      = shift or return 0;
	my $auimg     = $1 if $html =~ /(https:\/\/images.gr-assets.com\/authors\/.*?\.jpg)/gs;
	   $auimg     = $NOUSERIMGURL if !$auimg;
	my $auid      = $1 if $html =~ /author\/show\/([0-9]+)/;
	my $aunm      = $1 if $html =~ /<h1>Books by ([^<]+)/;
	   $aunm      = decode_entities( $aunm );
	my $ret       = 0;
	   
	while( $html =~ /<tr itemscope itemtype="http:\/\/schema.org\/Book">(.*?)<\/tr>/gs )
	{
		my $row = $1;
		my $id  = $1 if $row =~ /book\/show\/([0-9]+)/;
		
		my $tit = '';  # Book without title on https://www.goodreads.com/author/list/1094257
		   $tit = $1 if $row =~ /<span itemprop='name'>([^<]+)/;
		
		my $img = $1 if $row =~ /src="[^"]+/;
		my $num = $1 if $row =~ /([0-9.,]+) [rR]ating/;  # "1 rating", "2 ratings"
		   $num =~ s/,//g if $num;  # 1,600 -> 1600
		
		push @$books_ref, {
				id          => $id,
				title       => decode_entities( $tit ),
				isbn        => undef,
				author      => {
					id         => $auid,
					name       => $aunm,
					url        => _user_url( $auid, 1 ),
					works_url  => _author_books_url( $auid ),
					img_url    => $auimg,
					is_author  => 1,
					is_private => 0,
					is_female  => undef,
					is_friend  => undef
				},
				num_ratings => $num || 0,
				user_rating => undef,
				url         => _book_url( $id ),
				img_url     => $img };
		
		$ret++;
	}
	return $ret;
}




=head2 C<bool> _extract_followees( I<$result_hash_ref, $following_page_html_str> )

=over

=item * I<$result_hash_ref>: user_id => C<(L<%user|"%user">,...)>

=back

=cut

sub _extract_followees
{
	my $users_ref = shift;
	my $html      = shift;
	my $ret       = 0;
	
	while( $html =~ /<div class='followingItem elementList'>(.*?)<\/a>/gs )
	{
		my $row = $1;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		my $aid = $1 if $row =~ /\/author\/show\/([0-9]+)/;
		my $nam = $1 if $row =~ /img alt="([^"]+)/;
		   $nam = decode_entities( $nam );
		my $img = $1 if $row =~ /src="([^"]+)/;
		my $id  = $uid ? $uid : $aid;
		
		$users_ref->{$id} = { 
				id         => $id, 
				name       => $nam, 
				url        => _user_url( $id, $aid ),
				works_url  => $aid ? _author_books_url( $aid ) : undef,
				img_url    => $img,
				age        => undef,
				is_author  => $aid, 
				is_private => undef,
				is_female  => undef,
				is_friend  => 0 };
		
		$ret++;
	}
	return $ret;
}




=head2 C<bool> _extract_friends( I<$result_hash_ref, $friends_page_html_str> )

=over

=item * I<$result_hash_ref>: user_id => C<(L<%user|"%user">,...)>

=back

=cut

sub _extract_friends
{
	my $users_ref = shift;
	my $html      = shift;
	my $ret       = 0;
	
	while( $html =~ /<tr>\s*<td width="1%">(.*?)<\/td>/gs )
	{
		my $row = $1;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		my $aid = $1 if $row =~ /\/author\/show\/([0-9]+)/;
		my $nam = $1 if $row =~ /img alt="([^"]+)/;
		   $nam = decode_entities( $nam );
		my $img = $1 if $row =~ /src="([^"]+)/;
		my $id  = $uid ? $uid : $aid;
		
		$users_ref->{$id} = { 
				id         => $id, 
				name       => $nam, 
				url        => _user_url( $id, $aid ),
				works_url  => $aid ? _author_books_url( $aid ) : undef,
				img_url    => $img, 
				age        => undef,
				is_author  => $aid, 
				is_private => undef,
				is_female  => undef,
				is_friend  => 1 };
			
		$ret++;
	}
	return $ret;
}




=head2 C<bool> _extract_revs( I<$result_hash_ref, $on_progress_fn, $since_time_piece, $reviews_xhr_html_str> )

=over

=item * I<$result_hash_ref>: review_id => C<(L<%review|"%review">,...)> 

=back

=cut

sub _extract_revs
{
	my $revs_ref     = shift;
	my $progfn       = shift;
	my $since_tpiece = shift;
	my $html         = shift or return 0;  # < is \u003c, > is \u003e,  " is \" literally
	my $bid          = $1 if $html =~ /%2Fbook%2Fshow%2F([0-9]+)/;
	my $ret          = 0;
	
	while( $html =~ /div id=\\"review_\d+(.*?)div class=\\"clear/gs )
	{		
		my $row = $1;
		my $rid = $1 if $row =~ /\/review\/show\/([0-9]+)/;
		my $uid = $1 if $row =~   /\/user\/show\/([0-9]+)/;
		
		# img alt=\"David T\"   
		# img alt=\"0\"
		# img alt="\u0026quot;Greg Adkins\u0026quot;\"
		my $nam = $1 if $row =~ /img alt=\\"(.*?)\\"/;   
		   $nam = '"0"' if $nam eq '0';              # Avoid eval to false somewhere
		   $nam = decode_entities( $nam );
		   
		my $rat = () =  $row =~ /staticStar p10/g;   # count occurances
		my $txt = $1 if $row =~ /id=\\"freeTextContainer[^"]+"\\u003e(.*?)\\u003c\/span/;
		   $txt = $txt ? decode_entities( $txt ) : '';  # I expected rather '' than undef, so...
		
		# Parse-error "Jan 01, 1010" https://www.goodreads.com/review/show/1369192313
		my $dat = $1 if $row =~ /([A-Z][a-z]+ \d+, (19[7-9][0-9]|2\d{3}))/;
		my $dat_tpiece = $dat ? Time::Piece->strptime( $dat, '%b %d, %Y' ) : $EARLIEST; 
		
		next if $dat_tpiece < $since_tpiece;
		
		$revs_ref->{$rid} = {
				id   => $rid,
				user => { 
					id         => $uid, 
					name       => $nam, 
					url        => _user_url( $uid ),
					works_url  => undef,
					img_url    => undef,  # TODO
					age        => undef,
					is_author  => undef,
					is_private => undef,
					is_female  => undef,
					is_friend  => undef
				},
				rating     => $rat,
				rating_str => $rat ? ('[' . ($txt ? 'T' : '*') x $rat . ' ' x (5-$rat) . ']') : '[added]',
				review_url => _rev_url( $rid ),
				text       => $txt,
				date       => $dat_tpiece,
				book_id    => $bid };
		
		$ret++;
	}
	
	$progfn->( scalar keys %$revs_ref ) if $ret > 0;
	
	return $ret;
}




=head2 C<(L<%user|"%user">,...)> _extract_similar_authors( I<$author_id_to_skip, $similar_page_html_str> )

=cut

sub _extract_similar_authors
{
	my $uid_to_skip = shift;
	my $html        = shift;
	
	my @result;
	while( $html =~ /<li class='listElement'>(.*?)<\/li>/gs )
	{	
		my $row  = $1;
		my $auid = $1 if $row =~ /author\/show\/([0-9]+)/;
		
		next if $auid eq $uid_to_skip;
		
		my $auimg = $1 if $row =~ /(https:\/\/images\.gr-assets\.com\/authors\/[^"]+)/;
		   $auimg = $NOUSERIMGURL if !$auimg;
		
		my $aunm = $1 if $row =~ /class="bookTitle" href="\/author\/show\/[^>]+>([^<]+)/;
		   $aunm = decode_entities( $aunm );
		   
		push @result, {
				id         => $auid,
				name       => $aunm, 
				url        => _user_url( $auid, 1 ),
				works_url  => _author_books_url( $auid ),
				img_url    => $auimg,
				age        => undef,
				is_author  => 1,
				is_private => 0,
				is_female  => undef,
				is_friend  => undef };
	}
	return @result;
}




=head2 C<int> _check_page( I<$url, $html> )

=over

=item * returns 0 ok, 1 warn (ignore), 2 error (retry)

=item * warns if sign-in page (https://www.goodreads.com/user/sign_in) or in-page message

=item * warns if "page unavailable, Goodreads request took too long"

=item * warns if "page not found" 

=item * error if page unavailable: "An unexpected error occurred. 
        We will investigate this problem as soon as possible — please 
        check back soon!"

=item * error if over capacity (TODO UNTESTED):
        "<?>Goodreads is over capacity.</?> 
        <?>You can never have too many books, but Goodreads can sometimes
        have too many visitors. Don't worry! We are working to increase 
        our capacity.</?>
        <?>Please reload the page to try again.</?>
        <a ...>get the latest on Twitter</a>"
        https://pbs.twimg.com/media/DejvR6dUwAActHc.jpg
        https://pbs.twimg.com/media/CwMBEJAUIAA2bln.jpg
        https://pbs.twimg.com/media/CFOw6YGWgAA1H9G.png  (with title)

=item * error if maintenance mode (TODO UNTESTED):
        "<?>Goodreads is down for maintenance.</?>
        <?>We expect to be back within minutes. Please try again soon!<?>
        <a ...>Get the latest on Twitter</a>"
        https://pbs.twimg.com/media/DgKMR6qXUAAIBMm.jpg
        https://i.redditmedia.com/-Fv-2QQx2DeXRzFBRKmTof7pwP0ZddmEzpRnQU1p9YI.png

=item * error if website temporarily unavailable (TODO UNTESTED):
        "Our website is currently unavailable while we make some improvements
        to our service. We'll be open for business again soon,
        please come back shortly to try again. <?>
        Thank you for your patience." (No Alice error)
        https://i.gr-assets.com/images/S/compressed.photo.goodreads.com/hostedimages/1404319071i/10224522.png

=back

=cut

sub _check_page
{
	my $url  = shift;
	my $html = shift;
	
	# Try to be precise, don't stop just because someone wrote a pattern 
	# in his review or a book title. Characters such as < and > are 
	# encoded in user texts:
	
	warn "\n[WARN] Sign-in for $url => Cookie invalid or not set: set_good_cookie_file()\n"
		and return 1
			if $html =~ /<head>\s*<title>\s*Sign in\s*<\/title>/s;
	
	warn "\n[WARN] Not found: $url\n"
		and return 1
			if $html =~ /<head>\s*<title>\s*Page not found\s*<\/title>/s;
	
	
	warn "\n[ERROR] Goodreads.com \"temporarily unavailable\".\n"
		and return 2
			if $html =~ /Our website is currently unavailable while we make some improvements/s; # TODO improve
			
	warn "\n[ERROR] Goodreads.com encountered an \"unexpected error\".\n"
		and return 2
			if $html =~ /<head>\s*<title>\s*Goodreads - unexpected error\s*<\/title>/s;
	
	warn "\n[ERROR] Goodreads.com is over capacity.\n"
		and return 2
			if $html =~ /<head>\s*<title>\s*Goodreads is over capacity\s*<\/title>/s;
	
	warn "\n[ERROR] Goodreads.com is down for maintenance.\n"
		and return 2
			if $html =~ /<head>\s*<title>\s*Goodreads is down for maintenance\s*<\/title>/s;
	
	
	return 0;
}




=head2 C<string> _html( I<$url> )

=over

=item * HTML body of a web document

=item * might stop process on severe problems

=back

=cut

sub _html
{
	my $url = shift or return '';
	my $result;
	
	$result = $_cache->get( $url ) 
		if $_cache_age ne $EXPIRES_NOW;
	
	return $result 
		if defined $result;
	
DOWNLOAD:
	state $curl;
	my    $curl_ret;
	my    $state;
	my    $buf;
	
	$curl = WWW::Curl::Easy->new if !$curl;

	$curl->setopt( $curl->CURLOPT_URL,            $url       );
	$curl->setopt( $curl->CURLOPT_REFERER,        $url       );  # https://www.goodreads.com/...  [F5]
	$curl->setopt( $curl->CURLOPT_USERAGENT,      $USERAGENT );
	$curl->setopt( $curl->CURLOPT_COOKIE,         $_cookie   ) if $_cookie;
	$curl->setopt( $curl->CURLOPT_HTTPGET,        1          );
	$curl->setopt( $curl->CURLOPT_FOLLOWLOCATION, 1          );
	
	$curl->setopt( $curl->CURLOPT_HEADER,         0          );
	$curl->setopt( $curl->CURLOPT_WRITEDATA,      \$buf      );
	
	# Performance options, avoid slow SSL ops somehow (frq. handshakes etc):
	$curl->setopt( $curl->CURLOPT_TIMEOUT,        60         );
	$curl->setopt( $curl->CURLOPT_CONNECTTIMEOUT, 60         );
	$curl->setopt( $curl->CURLOPT_TCP_KEEPALIVE,  1          );
	$curl->setopt( $curl->CURLOPT_TCP_KEEPIDLE,   120        );
	$curl->setopt( $curl->CURLOPT_TCP_KEEPINTVL,  60         );
	$curl->setopt( $curl->CURLOPT_SSL_VERIFYPEER, 0          );
	
	$curl_ret = $curl->perform;
	$result    = $buf;
	
	warn sprintf( "\n[ERROR] %s %s\n", $curl->strerror( $curl_ret ), $curl->errbuf )
		unless $curl_ret == 0;
	
	$state = $curl_ret == 0 ? _check_page( $url, $result ) : 2;
	
	$_cache->set( $url, $result, $_cache_age ) 
		if $state == 0;
	
	if( $state > 1 )
	{
		say "[INFO ] Retrying in 3 minutes... Press CTRL-C to exit";
		$curl = undef;
		sleep 3*60;
		goto DOWNLOAD;
	}
	
	return $result;
}





1;
__END__


