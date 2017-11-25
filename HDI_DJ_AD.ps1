Configuration HDI_DJ_AD 
{ 
   param
   (
   )
    
    Import-DscResource -ModuleName xActiveDirectory

    Node localhost
    {
        Script AddADDSFeature {
            SetScript = {
				Install-WindowsFeature AD-Domain-Services
				Install-WindowsFeature RSAT-AD-Tools
				Install-WindowsFeature RSAT-ADDS
				Install-WindowsFeature RSAT-DNS-Server
            }
            GetScript =  { @{} }
            TestScript = { $false }
        }
   }
}
