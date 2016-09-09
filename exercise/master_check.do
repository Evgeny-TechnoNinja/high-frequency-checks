/*----------------------------------------*
 |file:    master_check.do                | 
 |project: high frequency checks          |
 |author:  christopher boyer              |
 |         matthew bombyk                 |
 |         innovations for poverty action |
 |date:    2016-02-13                     |
 *----------------------------------------*/

// this line adds standard boilerplate headings
ipadoheader, version(13.0)
use "survey_data.dta", clear
 
/*
 overview:
   this file contains the following data quality checks...
     1. Check that all interviews were completed
     2. Check that there are no duplicate observations
     3. Check that all surveys have consent
     4. Check that certain critical variables have no missing values
     5. Check that follow up record ids match original
     6. Check skip patterns and survey logic
     7. Check that no variable has all missing values
     8. Check hard/soft constraints
     9. Check specify other vars for items that can be included
     10. Check that date values fall within survey range
     11. Check that there are no outliers for unconstrained vars
*/

// dtanotes

// local file definitions (EDIT THESE)
local infile     "hfc_inputs.xlsx"
local outfile    "hfc_outputs.xlsx"
local repfile    "hfc_replacements.xlsx"
local enumdb     "hfc_enumerators.xlsx"
local researchdb "hfc_research.xlsx"
*local master     "master_tracking_list.dta"

// local variable definitions
local date       "SubmissionDate"
local id         "id"
local enum       "enumid"

// local options definitions
local target     2000
local sd     	 "sd"
local nolabel    "nolabel"
local replace    ""

/* =============================================================== 
   ================== Pre-process Import Data  =================== 
   =============================================================== */
   
qui {
	// generate start and end dates from SCTO values
	g startdate = dofc(starttime)
	g enddate = dofc(endtime)
	format %td startdate enddate

	// recode don't know/refusal values
	ds, has(type numeric)
	local numeric `r(varlist)'
	recode `numeric' (999 = .d)
	recode `numeric' (998 = .r)
	recode `numeric' (888 = .n)
	
	// get the current date
	local today = date(c(current_date), "DMY")
	local today_f : di %tdnn/dd/YY `today'
	
	// get total number of interviews
	local n = _N
}


/* =============================================================== 
   ================== Import globals from Excel  ================= 
   =============================================================== */

ipacheckimport using "`infile'"


/* =============================================================== 
   ================= Replacements and Corrections ================ 
   =============================================================== */
/* 
readreplace using "hfc_replacements.xlsx", ///
  id("id") ///
	variable("variable") ///
	value("newvalue") ///
	excel ///
	import(firstrow)
*/

/* =============================================================== 
   ==================== High Frequency Checks ==================== 
   =============================================================== */
set trace off
ipachecksummary using `outfile', target(`target') modify
local row = `r(i)'

/* <=========== HFC 1. Check that all interviews were completed ===========> */
ipacheckcomplete ${variable1}, complete(${complete_value1}) ///
  percent(${complete_percent1}) ///
  id(`id') ///
  enumerator(`enum') ///
  keepvars("${keep1}") ///
  saving(`outfile') ///
  sheetreplace `nolabel'
	
putexcel F`row'=(`r(nincomplete)')


/* <======== HFC 2. Check that there are no duplicate observations ========> */
ipacheckdups ${variable2}, id(`id') ///
  enumerator(`enum') ///
  keepvars(${keep2}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'

putexcel G`row'=(`r(ndups1)')
	
	
/* <============== HFC 3. Check that all surveys have consent =============> */
ipacheckconsent ${variable3}, consentvalue(${consent_value3}) ///
  id(`id') ///
  enumerator(`enum') ///
  keepvars(${keep3}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'

putexcel H`row'=(`r(noconsent)')


/* <===== HFC 4. Check that critical variables have no missing values =====> */
ipachecknomiss ${variable4}, id(`id') /// 
  enumerator(`enum') ///
  keepvars(${keep4}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'
		
putexcel I`row'=(`r(nmiss)')
	
	
/* <======== HFC 5. Check that follow up record ids match original ========> */
/*ipacheckfollowup ${variable5} using `master', id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace

putexcel J`row'=(`r(discrep)') */


/* <====== HFC 6. Check that no variable has only one distinct value ======> */
ipacheckskip ${variable6}, assert(${assert6}) ///
  condition(${if_condition6}) ///
  id(`id') ///
  enumerator(`enum') ///
  keepvars(${keep6}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'
	
putexcel K`row'=(`r(nviol)')
		 
		 
/* <======== HFC 7. Check that no variable has all missing values =========> */
ipacheckallmiss ${variable7}, id(`id') ///
  enumerator(`enum') ///
  saving(`outfile') ///
  sheetreplace `nolabel'

putexcel L`row'=(`r(nallmiss)')


/* <=============== HFC 8. Check for hard/soft constraints ================> */
ipacheckconstraints ${variable8}, smin(${soft_min8}) ///
  smax(${soft_max8}) ///
  id(`id') ///
  enumerator(`enum') ///
  keepvars(${keep8}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'

putexcel M`row' =(`r(nsoft)' + `r(nhard)') 
		 

/* <================== HFC 9. Check specify other values ==================> */
ipacheckspecify ${specify_variable9}, ///
  othervars(${other_variable9}) ///
  id(`id') ///
  enumerator(`enum') ///
  keepvars(${keep9}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'

putexcel N`row'=(`r(nspecify)')

	
/* <========== HFC 10. Check that dates fall within survey range ==========> */
ipacheckdates ${startdate10} ${enddate10}, surveystart(${surveystart10}) ///
  id(`id') ///
  enumerator(`enum') ///
  keepvars(${keep10}) ///
  saving(`outfile') ///
  sheetreplace `nolabel'

putexcel O`row'=(`r(missing)' + `r(diff_end)' +  ///
  `r(diff_start)' + `r(diff_today)')
		 

/* <============= HFC 11. Check for outliers in unconstrained =============> */
ipacheckoutliers ${variable11}, id(`id') ///
  enumerator(`enum') ///
  multiplier(${multiplier11}) ///
  keepvars(${keep11}) ///
  saving(`outfile') ///
  sheetreplace `nolabel' `sd'

putexcel P`row'=(`r(noutliers)')


/* ===============================================================
   =============== User Checks Programming Template ==============
   =============================================================== */


/* ===============================================================
   ================= Create Enumerator Dashboard =================
   =============================================================== */

ipacheckenum `enum' using "hfc_enumerators.xlsx", ///
   dkrfvars(${dkrf_variable12}) ///
   missvars(${missing_variable12}) ///
   durvars(${duration_variable12}) ///
   exclude(${exclude_variable12}) ///
   subdate(${submission_date12})

   
/* ===============================================================
   ================== Create Research Dashboard ==================
   =============================================================== */

   /* coming soon! */