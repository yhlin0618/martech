# THIS FILE HAS BEEN ARCHIVED FOLLOWING R28 ARCHIVING STANDARD
# Date archived: 2025-04-07
# Reason: Combined into microCustomer.R under P15 Debug Efficiency Exception
# Replacement: microCustomer.R (contains UI, server, and defaults)

#' Default Values for Micro Customer Component
#'
#' This file provides standard default values for the micro customer component.
#' These defaults ensure that all UI outputs have appropriate values even when
#' data is unavailable or invalid, implementing the UI-Server Pairing Rule.
#'
#' @return Named list of output IDs and their default values
#' @export
microCustomerDefaults <- function() {
  list(
    # Customer history metrics
    dna_time_first = "N/A",
    dna_time_first_tonow = "0",
    
    # RFM metrics
    dna_rlabel = "N/A",
    dna_rvalue = "0",
    dna_flabel = "N/A",
    dna_fvalue = "0",
    dna_mlabel = "N/A",
    dna_mvalue = "0.00",
    
    # Customer activity metrics
    dna_cailabel = "N/A",
    dna_cai = "0.00",
    dna_ipt_mean = "0.0",
    
    # Value metrics
    dna_pcv = "0.00",
    dna_clv = "0.00",
    dna_cri = "0.00",
    
    # Prediction metrics
    dna_nrec = "N/A",
    dna_nrec_onemin_prob = "0%",
    
    # Status metrics
    dna_nesstatus = "N/A",
    
    # Transaction metrics
    dna_nt = "0.00",
    dna_e0t = "0.00"
  )
}