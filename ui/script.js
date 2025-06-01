let currentPage = 0;
let pages = [];

window.addEventListener('message', function (event) {
  if (event.data.action === 'openCraftingMenu') {
    buildPages(event.data.recipes);
    renderPages();
    // Mostrar a UI quando for carregada
    document.querySelector('.book-container').style.display = 'flex';  // Exibe a UI
  }
});

function buildPages(recipes) {
  pages = [];

  let summaryHTML = "<h2>Sumário</h2><ul>";
  const sortedRecipes = [...recipes].sort((a, b) => a.label.localeCompare(b.label));
  sortedRecipes.forEach((recipe, index) => {
    summaryHTML += `<li><a href="#" class="summary-link" data-index="${index + 1}">${recipe.label}</a></li>`;
    pages.push(renderRecipe(recipe));
  });
  summaryHTML += "</ul>";
  pages.unshift(summaryHTML); // Adiciona o sumário no início
}

document.getElementById('pageLeft').addEventListener('click', function () {
  prevPage();
});

document.getElementById('pageRight').addEventListener('click', function () {
  nextPage();
});

function renderRecipe(recipe) {
  let html = `<h2><img src="${recipe.image}" class="ingredient-title-image">${recipe.label}</h2>`;
  html += `
  <div class="recipe-info-row">
    <p><strong><i class="fa-solid fa-boxes-stacked icon-style"></i> Rendimento:</strong> ${recipe.output.amount}</p>
    <p><strong><i class="fa-solid fa-clock icon-style"></i> Tempo:</strong> ${recipe.duration / 1000}s</p>
  </div>
`;

html += `<p><strong><i class="fa-solid fa-pen-nib icon-style"></i> Ingredientes:</strong></p><ul>`;
recipe.required_items.forEach(item => {
  // Verificando se a imagem existe e adicionando ela à lista de ingredientes
  if (item.image) {
    // Exibe a imagem junto com a quantidade e o nome do item
    html += `<li><img src="${item.image}" class="ingredient-image"> ${item.amount}x ${item.label}</li>`;
  } else {
    // Exibe apenas a quantidade e o nome do item sem a imagem
    html += `<li>${item.amount}x ${item.label}</li>`;
  }
});

html += `</ul>`;
  // Verifica se a área de ferramentas está vazia
  if (recipe.required_tools && recipe.required_tools.length > 0) {
    html += `<p><strong><i class="fa-solid fa-toolbox icon-style"></i> Ferramentas:</strong></p><ul>`;
    recipe.required_tools.forEach(tool => {
      const amount = tool.amount || 1; // Se não estiver definido, assume 1
      if (tool.image) {
        html += `<li><img src="${tool.image}" class="ingredient-image"> ${amount}x ${tool.label}</li>`;
      } else {
        html += `<li>${amount}x ${tool.label}</li>`;
      }
    });
    html += `</ul>`;
  } else {
    html += `<p><strong><i class="fa-solid fa-toolbox icon-style"></i> Ferramentas:</strong> Nenhuma</p>`;
  }

  // Adiciona campo de quantidade e botão "Produzir"
  html += `
  <div class="recipe-actions">
    <label for="quantityInput"> <i class="fa-solid fa-box-open icon-style"></i> Quantidade: </label>
    <input 
      type="number" 
      id="quantityInput" 
      min="1" 
      step="1" 
      value="1" 
      onclick="preventClickChange(event)" 
      oninput="validateInput(this)" 
    >
    <button id="produceButton-${recipe.id}">
      <i class="fa-solid fa-gear"></i> Produzir
    </button>
  </div>
  `;

  return html;
}

function validateInput(inputElement) {
  let value = inputElement.value;
  value = value.replace(/[^0-9]/g, ''); // Remove tudo que não for número
  if (!value || parseInt(value) < 1) {
    value = '1';
  }
  inputElement.value = value;
}

document.addEventListener('wheel', function (e) {
  if (document.activeElement.id === 'quantityInput') {
    e.stopPropagation();
  }
}, { passive: false });

document.addEventListener('keydown', function (e) {
  if (document.activeElement.id === 'quantityInput') {
    if (e.key === 'ArrowUp' || e.key === 'ArrowDown') {
      e.stopPropagation();
    }
  }
});

// Previne o clique de alterar a página quando clicamos nos botões ou inputs
function preventClickChange(event) {
  event.stopPropagation(); // Impede a propagação do clique para os eventos de navegação
}

// Função para enviar a produção
function produceItem(recipeId) {
  const quantity = document.getElementById(`quantityInput`).value;
  if (quantity && parseInt(quantity) > 0) {
    $.post('https://btc-craft/produceItem', JSON.stringify({
      recipe: recipeId,
      quantity: parseInt(quantity)
    }), function (response) {
      document.querySelector('.book-container').style.display = 'none';
      // closeCraftingMenu();
      // Reabrir o menu novamente após a produção
      // Aqui você pode reabrir o menu ou apenas deixar o estado intacto
    });
  } else {
    alert('Por favor, insira uma quantidade válida.');
  }
}

// Atualizando a renderização das páginas
function renderPages() {
  document.getElementById('pageLeft').innerHTML = pages[currentPage] || '';
  document.getElementById('pageRight').innerHTML = pages[currentPage + 1] || '';
}

// Funções de navegação das páginas
function goToRecipe(index) {
  console.log("Indo para página da receita:", index);
  currentPage = index % 2 === 0 ? index : index - 1; // Sempre para a página da esquerda
  renderPages();
}

function nextPage() {
  if (currentPage + 2 < pages.length) {
    const rightPage = document.getElementById('pageRight');
    rightPage.classList.add('page-turn-animation');
    setTimeout(() => {
      rightPage.classList.remove('page-turn-animation');
      currentPage += 2;
      renderPages();
    }, 600);
  }
}

function prevPage() {
  if (currentPage - 2 >= 0) {
    const leftPage = document.getElementById('pageLeft');
    leftPage.classList.add('page-turn-back-animation');
    setTimeout(() => {
      leftPage.classList.remove('page-turn-back-animation');
      currentPage -= 2;
      renderPages();
    }, 600);
  }
}

document.getElementById('pageLeftClick').addEventListener('click', () => {
  prevPage();
});

document.getElementById('pageRightClick').addEventListener('click', () => {
  nextPage();
});

// Adiciona evento de clique para os links no sumário
document.addEventListener('click', function (e) {
  const link = e.target.closest('.summary-link');
  if (link) {
    e.preventDefault();
    const index = parseInt(link.dataset.index);
    goToRecipe(index);
  }
});

// Fecha o menu ao pressionar ESC
document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') {
    closeCraftingMenu();
  }
});

function closeCraftingMenu() {
  // Apenas oculta o menu, mas não limpa o conteúdo
  document.querySelector('.book-container').style.display = 'none';

  // Enviar evento para o servidor (se necessário)
  $.post('https://btc-craft/closeMenu', JSON.stringify({}));
}

document.addEventListener('click', function (e) {
  const button = e.target.closest('button[id^="produceButton-"]');
  if (button) {
    e.stopPropagation();
    const recipeId = button.id.replace('produceButton-', '');
    produceItem(recipeId);
  }
});