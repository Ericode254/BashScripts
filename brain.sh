# get the filename from the user
read -p "Enter the file name: " fileName

# create the file
touch $fileName

# check if the input is a file
if [[ -f $fileName ]]; then
  # open the file with nvim using an obsidian template
  NVIM_APPNAME=nvim.bak3 nvim $fileName -c ":ObsidianTemplate"

  # move the file to my notes section
  mv $fileName $HOME/vaults/personal/Notes/
fi
