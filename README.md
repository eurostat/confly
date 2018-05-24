confly
======

Implementation of disclosure control methods for microdata confidentiality on the fly.
---

**About**

This project supports the implementation and testing of the cell key method for the anonymisation of _Eurostat_ survey data, _e.g._ the [census hub](http://ec.europa.eu/eurostat/web/population-and-housing-census/overview) and 
[Labour Force Survey](http://ec.europa.eu/eurostat/web/microdata/european-union-labour-force-survey) (LFS). 

<table align="center">
    <tr> <td align="left"><i>status</i></td> <td align="left">since 2017</b></td></tr> 
    <tr> <td align="left"><i>contributors</i></td> 
    <td align="left" valign="middle">
<a href="https://github.com/bachfab"><img src="https://github.com/bachfab.png" width="40"></a>
</td> </tr> 
    <tr> <td align="left"><i>license</i></td> <td align="left"><a href="https://joinup.ec.europa.eu/sites/default/files/eupl1.1.-licence-en_0.pdfEUPL">EUPL</a> </td> </tr> 
</table>

**Description**

* census (not provided here): the cell key method has been implemented to the census data; see original source code [here](https://ec.europa.eu/eurostat/cros/content/3-random-noise-cell-key-method_en);
* [lfs](lfs): the standard cell key method is adapted to the structure of the LFS data:
  * various data analyses are  run, and output results are compared; 
  * information loss, efficiency and processing time are evaluated;
  * an overall fit-for-purpose analysis of the cell-key method in the context of ad-hoc LFS queries is performed.

**Note**

The following `SAS` code can be used for the conversion of unique record identifiers into pseudo-random record keys:

```sas
format rkey best32.; /* cell key: define rkey format */
hash_hex = put(md5(COUNTRY||YEAR||QUARTER||HHNUM||HHSEQNUM), hex32.); /* cell key: first compute MD5 hash */
hash_int = input(hash_hex, IB4.); /*  cell key: convert to int (IB8. not accepted by RANUNI) */
call ranuni(hash_int, rkey); /* cell key: then compute actual rkey in [0, 1] */
```

It is foreseen that a similar approach will also be adopted for the anonymisation of 
[EU Statistics on Income and Living Conditions](http://ec.europa.eu/eurostat/web/microdata/european-union-statistics-on-income-and-living-conditions) (EU-SILC) data.

**<a name="resources"></a>Other resources**

* Statistical disclosure tools [sdcTools](https://github.com/sdcTools), in particular [sdcTable](https://github.com/sdcTools/sdcTable) 
and [tauargus](https://github.com/sdcTools/tauargus).
* [Codes and instructions](https://ec.europa.eu/eurostat/cros/content/testing-recommendations-codes-and-instructions_en) 
for protection of Census data in the ESS for the Census 2021 round; test ptables are also provided.
* [Table builder](http://www.abs.gov.au/websitedbs/censushome.nsf/home/tablebuilder) of the Australian Bureau of Statistics. 

**<a name="References"></a>References**

* A. Bujnowska,  W. Kloek, and F. Bach (2018): 
**Statistical confidentiality: New initiatives in the European Statistical System**, to appear in _Proc._ Quality Conference.
* F. Bach and A. Bujnowska (2018): [**Access to European microdata for scientific purposes**](https://ec.europa.eu/eurostat/cros/system/files/item_13_access_to_microdata-fb-final.pptx), _Pres._ DIME/ITDG.
* F. Bach (2017): [**Short illustration of the cell key algorithm**](https://ec.europa.eu/eurostat/cros/system/files/cell_key_algorithm.pptx).
* S. Giessing (2016): **Computational issues in the design of transition probabilities and disclosure risk Estimation for additive noise**, _Proc._ 
International Conference on Privacy in Statistical Databases, LCNS 9867, doi: [10.1007/978-3-319-45381-1_18](https://doi.org/10.1007/978-3-319-45381-1_18).
* J. Chipperfield, D. Gow, and B. Loong (2016):
[**The Australian Bureau of Statistics and releasing frequency tables via a remote server**](https://content.iospress.com/download/statistical-journal-of-the-iaos/sji969?id=statistical-journal-of-the-iaos%2Fsji969),
_Statistical Journal of the IAOS_, 32(1):53–64, doi: [10.3233/SJI-160969](https://doi.org/10.3233/SJI-160969).
* G. Thompson, S. Broadfoot, and D. Elazar (2013): 
[**Methodology for the automatic confidentialisation of statistical outputs from remote servers at the Australian Bureau of Statistics**](http://www.unece.org/fileadmin/DAM/stats/documents/ece/ces/ge.46/2013/Topic_1_ABS.pdf),
_Proc._ UNECE/Eurostat work session on statistical data confidentiality.
* Weblink [Protecting confidentiality with statistical disclosure control](https://www.ons.gov.uk/census/2011census/howourcensusworks/howwetookthe2011census/howweplannedfordatadelivery/protectingconfidentialitywithstatisticaldisclosurecontrol). See in particular the explanation of the cell-key method in the report on [**Evaluating a statistical disclosure control (SDC) strategy for 2011 Census outputs**](https://www.ons.gov.uk/file?uri=/census/2011census/howourcensusworks/howwetookthe2011census/howweplannedfordatadelivery/protectingconfidentialitywithstatisticaldisclosurecontrol/sdc-evaluation-for-2011-census-tabular-outputspublicfinal_tcm77-189751.pdf), pages 36-41.
